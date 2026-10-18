# frozen_string_literal: true

namespace :coverage do
  desc "Generate combined coverage report from all SimpleCov sources"
  task :report do
    require "json"

    coverage_file = Rails.root.join("coverage/.resultset.json")

    unless File.exist?(coverage_file)
      puts "Coverage file not found. Run tests first: bin/rails test"
      exit 1
    end

    coverage = JSON.parse(File.read(coverage_file))

    # Combine all sources using max for each line
    combined = {}

    coverage.each do |source_name, source_data|
      next unless source_data["coverage"]

      source_data["coverage"].each do |file, file_data|
        next unless file.include?("app/")

        combined[file] ||= []
        lines = file_data["lines"]

        # Expand array if needed
        if combined[file].length < lines.length
          combined[file] += [ nil ] * (lines.length - combined[file].length)
        end

        # Combine lines using max
        lines.each_with_index do |val, i|
          if val.nil?
            combined[file][i] ||= nil
          elsif combined[file][i].nil?
            combined[file][i] = val
          else
            combined[file][i] = [ combined[file][i], val ].max
          end
        end
      end
    end

    # Calculate coverage
    total_relevant = 0
    total_covered = 0
    files_below_100 = []

    combined.each do |file, lines|
      relevant = lines.compact.length
      covered = lines.count { |l| l && l > 0 }
      uncovered = relevant - covered

      next if relevant == 0

      total_relevant += relevant
      total_covered += covered

      coverage_pct = (covered.to_f / relevant * 100).round(1)
      short_file = file.sub(Rails.root.to_s + "/", "")

      if coverage_pct < 100
        files_below_100 << {
          file: short_file,
          coverage: coverage_pct,
          covered: covered,
          relevant: relevant,
          uncovered: uncovered
        }
      end
    end

    puts "=" * 80
    puts "COMBINED COVERAGE REPORT"
    puts "=" * 80
    puts
    puts "Total Line Coverage: #{(total_covered.to_f/total_relevant*100).round(2)}% (#{total_covered}/#{total_relevant})"
    puts

    if files_below_100.any?
      puts "Files below 100% coverage:"
      files_below_100.sort_by { |f| -f[:uncovered] }.each do |f|
        puts sprintf("  %-55s %5.1f%% (%d/%d)",
                     f[:file], f[:coverage], f[:covered], f[:relevant])
      end
    else
      puts "All files have 100% coverage!"
    end
  end
end
