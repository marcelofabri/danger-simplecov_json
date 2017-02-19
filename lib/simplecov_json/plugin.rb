module Danger
  # Report your Ruby app test suite code coverage.
  #
  # You can use [simplecov](https://github.com/colszowka/simplecov) to
  # gather code coverage data and a
  # [json formatter](https://github.com/vicentllongo/simplecov-json) so
  # this plugin can parse it.
  #
  # @example Report code coverage
  #
  #          simplecov.report('coverage/coverage.json')
  #
  # @see  marcelofabri/danger-simplecov_json
  # @tags ruby, code-coverage, simplecov
  #
  class DangerSimpleCovJson < Plugin
    # Parse a JSON code coverage file and report that information as a
    # message in Danger.
    # @return  [void]
    #
    def report(coverage_path, sticky: true)
      if File.exist? coverage_path
        coverage_json = JSON.parse(File.read(coverage_path), symbolize_names: true)
        metrics = coverage_json[:metrics]
        percentage = metrics[:covered_percent]
        lines = metrics[:covered_lines]
        total_lines = metrics[:total_lines]

        formatted_percentage = format('%.02f', percentage)
        message("Code coverage is now at #{formatted_percentage}% (#{lines}/#{total_lines} lines)", sticky: sticky)
      else
        fail('Code coverage data not found')
      end
    end

    def individual_report(coverage_path, current_project_path)
      if File.exist? coverage_path
        committed_files = (git.modified_files + git.added_files).map do |s|
          current_project_path + '/' + s
        end
        covered_files = JSON.parse(File.read(coverage_path), symbolize_names: true)[:files]
                            .select { |f| committed_files.include?(f[:filename]) }

        markdown individual_coverage_message(covered_files)
      else
        fail('Code coverage data not found')
      end
    end

    def individual_coverage_message(covered_files)
      require 'terminal-table'

      message = "### Code Coverage\n\n"
      table = Terminal::Table.new(
        headings: %w(File Coverage),
        style: { border_i: '|' },
        rows: covered_files.map do |file|
          [file[:filename], "#{format('%.02f', file[:covered_percent])}%"]
        end
      ).to_s
      message + table.split("\n")[1..-2].join("\n")
    end

    def self.instance_name
      'simplecov'
    end
  end
end
