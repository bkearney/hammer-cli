require File.join(File.dirname(__FILE__), 'test_helper')
require 'tempfile'


describe HammerCLI::AbstractCommand do

  context "exception handler" do

    class Handler
      def initialize(options={})
      end
      def handle_exception(e)
        raise e
      end
    end

    module ModA
      module ModB
        class TestCmd < HammerCLI::AbstractCommand
        end
      end
    end

    it "should return instance of hammer cli exception handler by default" do
      cmd = ModA::ModB::TestCmd.new ""
      cmd.exception_handler.must_be_instance_of HammerCLI::ExceptionHandler
    end

    it "should return instance of exception handler class defined in a module" do
      ModA::ModB.expects(:exception_handler_class).returns(Handler)
      cmd = ModA::ModB::TestCmd.new ""
      cmd.exception_handler.must_be_instance_of Handler
    end

    it "should return instance of exception handler class defined deeper in a module hierrarchy" do
      ModA.expects(:exception_handler_class).returns(Handler)
      cmd = ModA::ModB::TestCmd.new ""
      cmd.exception_handler.must_be_instance_of Handler
    end
  end

  context "logging" do

    before :each do
      @log_output = Logging::Appenders['__test__']
      @log_output.reset
    end

    it "should log what has been executed" do
      test_command = Class.new(HammerCLI::AbstractCommand).new("")
      test_command.run []
      @log_output.readline.strip.must_equal "INFO  HammerCLI::AbstractCommand : Called with options: {}"
    end

    class TestLogCmd < HammerCLI::AbstractCommand
      def execute
        logger.error "Test"
        0
      end
    end

    it "should have logger named by the class by default" do
      test_command = Class.new(TestLogCmd).new("")
      test_command.run []
      @log_output.read.must_include "ERROR  TestLogCmd : Test"
    end

    class TestLogCmd2 < HammerCLI::AbstractCommand
      def execute
        logger('My logger').error "Test"
        0
      end
    end

    it "should have logger that accepts custom name" do
      test_command = Class.new(TestLogCmd2).new("")
      test_command.run []
      @log_output.read.must_include "ERROR  My logger : Test"
    end

    class TestLogCmd3 < HammerCLI::AbstractCommand
      def execute
        logger.watch "Test", {}
        0
      end
    end

    it "should have logger that can inspect object" do
      test_command = Class.new(TestLogCmd3).new("")
      test_command.run []
      @log_output.read.must_include "DEBUG  TestLogCmd3 : Test\n{}"
    end

    class TestLogCmd4 < HammerCLI::AbstractCommand
      def execute
        logger.watch "Test", { :a => 'a' }, { :plain => true }
        0
      end
    end

    it "should have logger.watch output without colors" do
      test_command = Class.new(TestLogCmd4).new("")
      test_command.run []
      @log_output.read.must_include "DEBUG  TestLogCmd4 : Test\n{\n  :a => \"a\"\n}"
    end

    class TestLogCmd5 < HammerCLI::AbstractCommand
      def execute
        logger.watch "Test", { :a => 'a' }
        0
      end
    end

    it "should have logger.watch colorized output switch in settings" do
      test_command = Class.new(TestLogCmd5).new("")
      HammerCLI::Settings.clear
      HammerCLI::Settings.load(:watch_plain => true)
      test_command.run []
      @log_output.read.must_include "DEBUG  TestLogCmd5 : Test\n{\n  :a => \"a\"\n}"
    end
  end

end

