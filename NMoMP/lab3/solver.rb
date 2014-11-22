require_relative 'function.rb'

class Solver
  def initialize
    @ux0 = 323
    @urt = 273
    @r   = 0.05
    @lam = 455
    @c   = 460
    @ro  = 7900

    @vx0   = 0
    @vrt   = (@urt - @ux0).to_f / (@ux0)
    @n     = 1000
    @sigma = 0.5
    @tau   = 0.01
  end

  def solve
    h = 1.0 / @n
    @xs = []
    (@n+1).times { |i| @xs << i*h }
    ps = lambda do |i|
      x1 = i - 1
      x2 = i + 1
      x1 = 0 if x1 < 0
      x2 = i if i == @n
      (x1*x1 + x1*x2 + x2*x2)*h*h
    end
    xx = lambda do |i|
      x1 = i - 1
      x2 = i + 1
      x1 = 0 if i == 0
      x2 = i if i == @n
      (x1*x1 + x1*x2 + x2*x2)*h*h
    end
    res = []
    ys = Array.new(@n + 2, 0)
    50.times do
      as = []
      cs = []
      bs = []
      fs = []
      (@n).times do |i|
        i = i+1
        as << ps.call(i) / (h*h) * @sigma
        cs << -(xx.call(i) / @tau + @sigma / (h*h) * (ps.call(i+1) + ps.call(i)))
        bs << ps.call(i+1) / (h*h) * @sigma
        fs << xx.call(i) * (- ys[i] / @tau) - (1 - @sigma) / (h*h) * (ps.call(i+1) * (ys[i+1] - ys[i]) - ps.call(i) * (ys[i] - ys[i-1]))
      end
      cs[0] += as[0]
      fs[-1] -= bs[-1] * @vrt
      as[0] = bs[-1] = 0
      ys = progonka(as, bs, cs, fs)
      ys = [ys[0]] + ys + [@vrt]
      res << [@xs,ys]
    end
    res
  end

  private
  # solving equatin of form:
  # a[i]*x[i-1] + c[i]*x[i] + b[i]*x[i+1] = f[i] , i = 0..n
  # in assumtion that a[0] = 0, b[n-1] = 0 where n = c.size
  # Note: x[-1] and x[n] are undefined but coeficient with it are zeros
  def progonka(a,b,c,f)
    a,b,c,f = [a,b,c,f].map { |ar| ar.map(&:to_f) }
    al = [0]
    be = [0]
    n = a.size
    (0..n-1).each do |i|
      al << (-b[i] / (al[i]*a[i] + c[i]))
      be << ((f[i] - a[i] * be[i]) / (a[i] * al[i] + c[i]))
    end
    x = Array.new n
    x[n-1] = ( f[n-1] - a[n-1]*be[n-1] ) / (c[n-1] + a[n-1]*al[n-1])
    (n - 2).downto(0) do |i|
      x[i] = al[i+1]*x[i+1] + be[i+1]
    end
    x
  end
end