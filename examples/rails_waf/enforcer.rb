# app/controllers/concerns/enforcer.rb
require 'digest/sha1'
require 'equation'

module Enforcer
  extend ActiveSupport::Concern

  included do
    class_attribute :rule_stack, :rules_from_files
    before_action :enforce_rules
  end

  module ClassMethods
    def enforce(opts = {})
      self.rule_stack ||= []
      self.rule_stack << opts[:rule]
    end

    def enforce_from(opts = {})
      self.rules_from_files ||= []
      self.rules_from_files << opts[:key]
    end
  end

  private

  def engine
    EquationEngine.new(
      default: {
        controller: self.class.to_s,
        request: request,
        params: params,
        params_normalized: params.permit!.to_s.downcase
      },
      methods: {
        rand10: -> { rand(1..10) },
        any: ->(*more) { more.any? },
        all: ->(*more) { more.all? },
        none: ->(*more) { more.none? }
      }
    )
  end

  def fetch_rule(rule_str:)
    cache_key = Digest::SHA1.hexdigest rule_str

    # Cache the parsed version of the rule.
    # One offs don't matter much but parsing still adds up.
    Rails.cache.fetch("rule_#{cache_key}", expires_in: 12.hours) do
      engine.parse(rule: rule_str)
    end
  end

  def remote_rules
    return [] if self.rules_from_files.empty?

    # Cache the remote rules files so you're not synchronously
    # downloading files remotely on every request.
    Rails.cache.fetch('remote_rules', expires_in: 5.minutes) do
      self.rules_from_files.map do |rule_file|
        JSON.parse(ActiveStorage::Blob.service.download(rule_file))
      rescue ActiveStorage::FileNotFoundError
        []
      end.sum([])
    end
  end

  def enforce_rules
    (remote_rules + rule_stack + rules).each do |r|
      rule = fetch_rule(rule_str: r)
      result = engine.eval(rule: rule)
      Rails.logger.info("Evaluating rule: `#{r}` -> #{result}")

      return head :unauthorized if result
    end
  end

  def rules
    []
  end
end
