# Functions for extracting package usage from code
module PackageGrep
  class << self
    def ruby(code)
      patterns = [
        # require 'package'
        /^\s*require\s+["']([^"']{1,50})["']/m,
        # iruby-dependencies:
        #   gem 'package'
        #   gem 'package', require 'module'
        /^\s*gem\s+["']([^"']{1,50})["'](?:[^\n\r]{0,100}require:\s*["']([^"']{1,50})["'])?/m
      ]
      patterns
        .flat_map {|pattern| code.scan(pattern).flatten}
        .reject(&:nil?)
        .uniq
    end

    def ipydeps(code)
      # Common usages:
      # ipydeps.pip('package')
      # ipydeps.pip(['p1', 'p2', ...])
      ipydeps1 = code
        .scan(/^\s*ipydeps.pip\s*\(\s*\[?\s*'([^\)]{1,250})\)/m)
        .flatten
        .flat_map {|capture| capture.scan(/[\w-]+/)}

      # Less common:
      # var = ['list', 'of', 'packages']
      # ipydeps.pip(var)
      pattern2 = /
        ^\s*                    # start of line
        (\w+)\s*=\s*            # var =
        \[\s*'([^\]]{1,250})\]  # ['list', 'of', 'packages']
        .{0,100}?               # random junk
        ^\s*                    # start of line
        ipydeps.pip\s*\(\s*\1   # ipydeps.pip(var)
      /mx
      ipydeps2 = code
        .scan(pattern2)
        .map {|_var, list| list}
        .flat_map {|capture| capture.scan(/\w+/)}

      # Less common:
      # var = ['list', 'of', 'packages']
      # for i in var:
      #   ipydeps.pip(i)
      pattern3 = /
        ^\s*                      # start of line
        (\w+)\s*=\s*              # var =
        \[\s*'([^\]]{1,250}?)\]   # ['list', 'of', 'packages']
        .{0,100}?                 # random junk
        ^\s*                      # start of line
        for\s+(\w+)\s+in\s+\1\s*: # for i in var:
        .{0,200}?                 # random junk
        ^\s*                      # start of line
        ipydeps.pip\s*\(\s*\3     # ipydeps.pip(i)
      /mx
      ipydeps3 = code
        .scan(pattern3)
        .map {|_var, list, _i| list}
        .flat_map {|capture| capture.scan(/\w+/)}

      (ipydeps1 + ipydeps2 + ipydeps3).uniq
    end

    def python(code)
      # Handle 'import a as b, x as y, ...'
      imports = code
        .scan(/^\s*import\s+([\w ,]{1,100})(?:#|$)/m)
        .flatten
        .flat_map {|capture| capture.split(',').map {|p| p.split.first}}

      # Other patterns
      patterns = [
        # from package import thing
        /^\s*from\s+(\S{1,50})\s+import/m,
        # pip.main(['install', 'package'])
        /^\s*pip.main\s*\(\s*\[["']install["'],\s*["']([^"']{1,50})["']/m
      ]
      other = patterns
        .flat_map {|pattern| code.scan(pattern).flatten}
        .reject(&:nil?)

      (imports + ipydeps(code) + other).uniq
    end

    def R(code) # rubocop: disable Naming/MethodName
      code.scan(/^\s*library\((\w+)\)/).flatten.uniq
    end

    def cpp(code)
      code.scan(/^\s*#include <(\w+)>/).flatten.uniq
    end
  end
end
