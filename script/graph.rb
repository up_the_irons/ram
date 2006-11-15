#!/usr/bin/env ruby
# As seen on Matt Biddulph's site: http://www.hackdiary.com/archives/000093.html
require "config/environment"
Dir.glob("app/models/*rb") { |f|
    require f
}
puts "digraph x {"
Dir.glob("app/models/*rb") { |f|
    f.match(/\/([a-z_]+).rb/)
    classname = $1.camelize
    klass = Kernel.const_get classname
    if klass.superclass == ActiveRecord::Base
        puts classname
        klass.reflect_on_all_associations.each { |a|
            puts classname + " -> " + a.name.to_s.camelize.singularize + " [label="+a.macro.to_s+"]"
        }
    end
}
puts "}"