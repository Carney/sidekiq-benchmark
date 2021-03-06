require 'test_helper'

module Sidekiq
  module Benchmark
    module Test

      class WorkerTest < Minitest::Spec
        include Sidekiq::Benchmark::Worker

        before do
          Test.flush_db
          @worker = WorkerMock.new
        end

        it "should collect metrics" do
          metrics = @worker.benchmark.metrics

          @worker.metric_names.each do |metric_name|
            metrics[metric_name].wont_be_nil
          end

          @worker.benchmark.start_time.wont_be_nil
          @worker.benchmark.finish_time.wont_be_nil
          metrics[:assigned_metric].must_equal @worker.assigned_metric
        end

        it "should save metrics to redis" do
          Sidekiq.redis do |conn|
            total_time = conn.hget("#{@worker.benchmark.redis_key}:total", :job_time)
            total_time.wont_be_nil

            metrics = conn.hkeys("#{@worker.benchmark.redis_key}:stats")
            metrics.wont_be_empty
          end
        end

        it "should collect metrics with alter syntax" do
          worker = AlterWorkerMock.new
          metrics = worker.benchmark.metrics

          Sidekiq.redis do |conn|
            metric_set = conn.hkeys("#{worker.benchmark.redis_key}:stats")
            metric_set.must_be_empty
          end

          worker.metric_names.each do |metric_name|
            metrics[metric_name].wont_be_nil
          end

          worker.benchmark.finish_time.must_be_nil

          worker.finish

          worker.benchmark.finish_time.wont_be_nil

          Sidekiq.redis do |conn|
            metric_set = conn.hkeys("#{worker.benchmark.redis_key}:stats")
            metric_set.wont_be_empty
          end
        end

      end
    end
  end
end
