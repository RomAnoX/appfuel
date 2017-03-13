module Appfuel
  # Used in the validation system by custom predicates to ask the question if
  # an entity exists in the database
  class RepositoryRunner
    attr_reader :repo_namespace, :criteria_class

    # The call relies on the fact that we can build a criteria find the
    # correct repo and call the exists? interface on that repo. The identity
    # of any given repo requires its namespace + its class name.
    #
    # @param namespace [String] fully qualified namespace string fro repos
    # @param criteria_class [Class] class used to represent the criteria
    # @returns [ExistsInDbRunner]
    def initialize(namespace, criteria_class)
      @repo_namespace = namespace
      @criteria_class = criteria_class
    end

    def create_criteria(entity_key, opts = {})
      criteria_class.new(entity_key, opts)
    end

    def query(criteria)
      load_repo(criteria).query(criteria)
    end

    # @param entity_key [String] the type identifier for an entity
    # @param opts [Hash] one attr => value pair is required
    #                        repo => name is optional
    #
    # @return [Bool]
    def exists?(entity_key, opts = {})
      fail "opts must be a hash" unless opts.is_a?(Hash)

      criteria_opts = {}
      if opts.key?(:repo)
        criteria_opts[:repo] = opts.delete(:repo)
      end
      fail "opts hash must have one attr => value pair" if opts.empty?

      property, value = opts.first
      criteria = create_criteria(entity_key, criteria_opts)
      criteria.exists(property, value)

      load_repo(criteria).exists?(criteria)
    end


    private

    def load_repo(criteria)
      klass  = "#{repo_namespace}::#{criteria.repo_name}"
      unless Kernel.const_defined?(klass)
        fail "RepositoryRunner: failed - repo #{klass} not defined"
      end

      Kernel.const_get(klass).new
    end
  end
end
