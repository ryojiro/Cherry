class Cherry
  @@code = ''
  @@space_f = {} 
  @@global = {}
  @@keywords = {
    '+' => :add,
    '-' => :sub,
    '*' => :mul,
    '/' => :div,
    '%' => :mod,
    '<-' => :assignment,
    '>=' => :greater_equal,
    '<=' => :less_equal,
    '>' => :greater,
    '<' => :less,
    '=-=' => :equal,
    '=!=' => :not_equal,
    '&&' => :and,
    '||' => :or,
    '(' => :lpar,
    ')' => :rpar,
    '{' => :lbra,
    '}' => :rbra,
    'if' => :if,
    'then' => :then,
    'else' => :else,
    'while' => :while,
    'for' => :for,
    '|' => :pipe,
    'function' => :function,
    'call' => :call,
    'print' => :print,
    'input' => :input,
  }
  @@operator = [
    :equal,
    :not_equal,
    :greater,
    :greater_equal,
    :less,
    :less_equal,
    :and,
    :or,
    :assignment
  ]
  @@infunction = false
  
  def get_token()
    if @@code =~ /\A\s*(#{@@keywords.keys.map{|t|Regexp.escape(t)}.join('|')})/
      @@code = $'
      return @@keywords[$1]
    elsif @@code =~ /\A\s*([0-9.]+)/
      @@code = $'
      return $1.to_f
    elsif @@code =~ /\A\s*([A-Za-z]+\w*)\(\)/
      @@code = $'
      unget_token($1)
      return :call
    elsif @@code =~ /\A\s*(\#?[A-Za-z]+\w*(?:\[\w*\])?)/
      @@code = $'
      return $1.to_s
    elsif @@code =~ /\A\s*(\'\S*\')/
      @@code = $'
      return $1.to_s
    elsif @@code =~ /\A\s*\z/
      return nil
    end
    return :bad_token
  end
  
  def unget_token(token)
    if token.is_a? Numeric
      @@code = token.to_s + @@code
    elsif token.is_a?(String)
      @@code = token + ' ' + @@code
    else
      @@code = @@keywords.key(token) ? @@keywords.key(token) + @@code : @@code
    end
  end
  
  def sentences()
    unless s = sentence()
      raise Exception, "can't find any sentences"
    end
    result = [:block, s] 
    while s = sentence()
      result << s
    end
    return result
  end
  
  def sentence()
    token = get_token()
    case token
    when :lbra
      result = sentences()
    when :rbra
      return result
    when :print
      result = [:print, andor()]
    when :while
      result = [:while, andor(), sentence()]
    when :if
      if1 = andor()
      if get_token() == :then then
        if2 = sentence()
      else
        raise Exception, "then is missed"
      end
      if (temp = get_token()) == :else then
        if3 = sentence()
        result = [:if, if1, if2, if3]
      else
        unget_token(temp)
        result = [:if, if1, if2, nil]
      end
    when :function
      result = [:function, get_token(), sentence()]
      unless result[1].is_a? String
        raise Exception, "should use string as name of function"
      end
    when :call
      result = [:call, get_token()]
      unless result[1].is_a? String
        raise Exception, "should use string as name of function"
      end
    when :for
      temp1 = sentence()
      if get_token == :pipe then
        temp2 = sentence()
      else
        raise Exception, "missed pipe_1"
      end
      if get_token == :pipe then
        temp3 = sentence()
      else
        raise Exception, "missed pipe_2"
      end
      temp4 = sentence()
      result = [:for, temp1, temp2, temp3, temp4] 
    when :bad_token
      raise Exception, "requested token is missed"
    end
    if token.is_a?(String)
      temp = token
      temp2 = get_token()
      if @@operator.include?(temp2) then
        unget_token(temp2)
        unget_token(temp)
        result = andor()
      else
        raise Exception, 'wrong sentense'
      end
    end
    return result
  end

  def andor()
    result = overexp()
    while true
      token = get_token()
      unless token == :and or token == :or
        unget_token(token)
        break
      end
      result = [token, result, overexp()]
    end
    return result
  end
  
  def overexp()
    result = expression()
    while true
      token = get_token()
      unless token == :assignment or token == :equal or token == :not_equal or token == :greater or token == :greater_equal or token == :less or token == :less_equal
        unget_token(token)
        break
      end
      result = [token, result, expression()]
    end
    return result
  end
  
  def expression()
    result = term()
    while true
      token = get_token()
      unless token == :add or token == :sub
        unget_token(token)
        break
      end
      result = [token, result, term()]
    end
    return result
  end
  
  def term()
    result = factor()
    while true
      token = get_token()
      unless token == :mul or token == :div or token == :mod
        unget_token(token)
        break
      end
      result = [token, result, factor()]
    end
    return result
  end
  
  def factor()
    token = get_token()
    minusflg = 1
    if token == :sub
      minusflg = -1
      token = get_token()
    end
    if token.is_a? Numeric
      return token * minusflg
    elsif token.is_a? String
      return token
    elsif token == :input
      result = [:input]
    elsif token == :lpar
      result = andor()
      unless get_token == :rpar
        raise Exception, "unexpected token"
      end
      return [:mul, minusflg, result]
    end
  end
  
  def eval(exp)
    if exp.instance_of?(Array)
      case exp[0]
      when :add
        return eval(exp[1]) + eval(exp[2])
      when :sub
        return eval(exp[1]) - eval(exp[2])
      when :mul
        return eval(exp[1]) * eval(exp[2])
      when :div
        return eval(exp[1]) / eval(exp[2])
      when :mod
        return eval(exp[1]) % eval(exp[2])
      when :equal
        return eval(exp[1]) == eval(exp[2]) ? 1 : 0
      when :not_equal
        return eval(exp[1]) != eval(exp[2]) ? 1 : 0
      when :greater
        return eval(exp[1]) > eval(exp[2]) ? 1 : 0
      when :greater_equal
        return eval(exp[1]) >= eval(exp[2]) ? 1 : 0
      when :less
        return eval(exp[1]) < eval(exp[2]) ? 1 : 0
      when :less_equal
        return eval(exp[1]) <= eval(exp[2]) ? 1 : 0
      when :and
        return (eval(exp[1]) != 0 && eval(exp[2]) != 0) ? 1 : 0
      when :or
        return (eval(exp[1]) != 0 || eval(exp[2]) != 0) ? 1 : 0
      when :print
        puts eval(exp[1]) =~ /\'(\S*)\'/ ? $1 : eval(exp[1])
      when :assignment
        if(exp[1] =~ /\#([A-Za-z]+\w*(?:\[\w\])?)/) then
          @@global[$1] = eval(exp[2])
        else
          @space[exp[1]] = eval(exp[2])
        end
      when :if
        if eval(exp[1]) != 0 then
          return eval(exp[2])
        elsif exp[3] != nil
          return eval(exp[3])
        end
      when :block
        1.upto(exp.length) do |e|
          eval(exp[e])
        end
      when :while
        while eval(exp[1]) != 0
          eval(exp[2])
        end
      when :for
        eval(exp[1])
        while  eval(exp[2]) != 0
          eval(exp[4])
          eval(exp[3])
        end
      when :function
        @@infunction = true
        @@space_f[exp[1]] = exp[2]
        @@infunction = false
      when :call
        func = Cherry.new
        func.eval(@@space_f[exp[1]])
      when :input
        temp = STDIN.gets.chomp
        if temp =~ /\d+/ then
          return temp.to_f
        elsif temp.is_a?(String) then
          return "\'#{temp}\'"
        else
          raise Exception, 'please type Number or String'
        end
      end
    else
      if exp.is_a?(String)
        if exp =~ /\A\s*\'(\S*)\'/ then
          return $1
        elsif(exp =~ /\#([A-Za-z]+\w*(?:\[\w\])?)/) then
          if @@global.key?($1)
            return @@global[$1]
          elsif @@infunction == false then
            raise Exception, "not assigned(global)"
          end
        else
          if @space.key?(exp) then
            return @space[exp]
          elsif @@infunction == false then
            raise Exception, "not assigned(instance)"
          end
        end
      else
        return exp
      end
    end
  end

  def initialize()
    @space = {}
  end
  
  def start()
    begin
      file = File.open(ARGV[0])
      @@code << file.read
      file.close
    rescue
      puts $!
    end
    #p @@code
    s = sentences()
    #p s
    eval(s)
    #p @space
    #p @@space_f
    #p @@global
  end
end 

cherry = Cherry.new
cherry.start()
