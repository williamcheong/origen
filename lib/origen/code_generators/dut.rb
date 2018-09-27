module Origen
  module CodeGenerators
    class Dut < Origen::CodeGenerators::Base
      desc <<-END
This generator creates a top-level model and associated resources for it, e.g. a controller.

The name of the model should be given, in lower case, optionally indicating the presence
of any namespacing within your application.
END

      def extract_model_name
        if args.size > 1 || args.size == 0
          msg = args.size > 1 ? 'Only one' : 'One '
          msg << "argument is expected by the dut generator, e.g. 'origen new dut my_soc', 'origen new dut socs/my_soc'"
          Origen.log.error(msg)
          exit 1
        end

        @namespaces = ARGV.first.downcase.split('/')

        @name = @namespaces.pop

        @namespaces.unshift(Origen.app.name.to_s) unless @namespaces.first == Origen.app.name.to_s
      end

      def create_model_file
        # @summary = ask 'Describe your plugin in a few words:'
        # template 'templates/code_generators/gemspec.rb', File.join(Origen.root, "#{Origen.app.name}.gemspec")
        template 'templates/code_generators/dut.rb', File.join(Origen.root, 'app', 'models', *@namespaces, "#{@name}.rb")
        template 'templates/code_generators/controller.rb', File.join(Origen.root, 'app', 'controllers', *@namespaces, "#{@name}_controller.rb")
        add_autoload @name, namespaces: @namespaces
      end

      def create_target
        contents = ''
        contents << ([Origen.app.name] + @namespaces).map { |n| n.to_s.camelcase }.join('::')
        contents << "::#{@name.to_s.camelcase}.new\n"

        create_file "#{Origen.root}/target/#{@name}.rb", contents
      end

      def completed
        puts
        puts 'New DUT model and target created, run the following command to select it in your workspace:'
        puts "  origen t #{@name}"
      end
    end
  end
end
