require 'java'

$pmap_jruby_timeout = 10

module PMap
  class Task
    include java.util.concurrent.Callable

    def initialize(proc, *params)
      @proc = proc
      @params = params
    end

    def call
      @proc.call(*@params)
    end
  end

  def self.included(base)
    base.module_eval do
      def peach(thread_count = nil, &proc)
        futures = submit_tasks(thread_count, proc)
        pretty_java_exception do
          futures.each {|f| f.get}
        end

        self
      end

      def pmap(thread_count = nil, &proc)
        futures = submit_tasks(thread_count, proc)
        pretty_java_exception do
          futures.map {|f| f.get}
        end
      end

      private

      def submit_tasks(thread_count, proc)
        futures = nil

        executor(thread_count) do |executor|
          futures = self.map do |item|
            executor.submit(Task.new(proc, item))
          end
        end

        futures
      end

      def pretty_java_exception
        result = nil

        begin
          result = yield
        rescue NativeException => ne
          # Unwrap the NativeException, then the ExecutionException
          raise ne.cause.cause
        end

        result
      end

      def executor(thread_count)
        java_import java.util.concurrent.Executors

        thread_count ||= $pmap_default_thread_count

        raise ArgumentError, "thread_count must be at least one." unless
          thread_count.nil? or (thread_count.respond_to?(:>=) and thread_count >= 1)

        executor = Executors.newFixedThreadPool(thread_count)

        yield executor

        executor.shutdown
        executor.awaitTermination($pmap_jruby_timeout, java.util.concurrent.TimeUnit::SECONDS)
      end
    end
  end
end
