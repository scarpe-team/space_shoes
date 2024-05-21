# frozen_string_literal: true

require "js"

module SpaceShoes
  class WasmCalls
    include Shoes::Log

    def initialize
      log_init("SpaceShoes::Wasm")
    end

    def js_integer?(num)
      if JS.global[:Number].isInteger(num)
        true
      else
        false
      end
    end

    def rubify(obj)
      type = obj.typeof
      case type
      when "string"
        obj.to_s
      when "number"
        if js_integer?(obj)
          obj.to_i
        else
          obj.to_f
        end
      when "undefined"
        nil
      else
        obj
      end
    end

    def bind(name, func = nil, &block)
      JS.global[:self][name.to_sym] = proc do |*args|
        args = args.map { |x| rubify(x) }
        (func ? func : block).call(*args)
      rescue => e
        @log.error(e)
        @log.error(e.backtrace)
      end
      defined?(JS.global[:self][name.to_sym])
    end

    def eval(command)
      JS.eval(command)
    end

    def init(command)
      @commands ||= []
      @commands << command
    end

    def set_title(title)
      JS.global[:document][:title] = title
    end

    def set_size(width, height, hint)
      #JS.global[:document][:body][:style][:width] = width
      #JS.global[:document][:body][:style][:height] = height
    end

    def navigate(string)
      # JS.eval('var empty =
      # `body {
      #   font-family: arial, Helvetica, sans-serif;
      #   margin: 0;
      #   height: 100%;
      #   overflow: hidden;
      # }
      # p {
      #   margin: 0;
      # }`;')
      # JS.eval("var head = document.head || document.getElementsByTagName('head')[0];")
      # JS.eval("var style = document.createElement('style');")
      # JS.eval("head.appendChild(style);")
      # JS.eval("style.type = 'text/css';")
      # # JS.eval("style.id = 'style-wvroot';")
      # JS.eval("head.id = 'head-wvroot';")
      # JS.eval("head.appendChild(style);")
      # JS.eval("style.appendChild(document.createTextNode(empty));")
      # JS.eval("var body = document.body;")
      # JS.eval("body.id = 'body-wvroot';")
      # JS.eval("var newDiv = document.createElement('div');")
      # JS.eval("newDiv.id = 'wrapper-wvroot';")
      # JS.eval("body.appendChild(newDiv);")

      style = JS.global[:document].createElement("style")
      style[:id] = "style-wvroot"
      style.appendChild(JS.global[:document].createTextNode("body {
        font-family: arial, Helvetica, sans-serif;
        margin: 0;
        height: 100%;
      }
      p {
        margin: 0;
      }"))
      JS.global[:document][:head].appendChild(style)
      JS.global[:document][:head][:id] = "head-wvroot"
      div = JS.global[:document].createElement("div")
      div[:id] = "wrapper-wvroot"
      JS.global[:document][:body].appendChild(div)
    end

    def run
      @commands.each { |command| JS.eval(command) }
    end

    def terminate
      # stub
    end
  end
end
