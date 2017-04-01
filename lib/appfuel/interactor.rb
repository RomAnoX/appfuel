module Appfuel
  class Interactor < Handler
    include CommandDependency
    class << self
      def resolve_dependencies(results = Dry::Container.new)
        super
        resolve_container(results)
        resolve_domains(results)
        resolve_commands(results)
        results
      end

      def feature_module
        self.parent
      end
    end

    def find_by_criteria(criteria)
      cmd(:find, search: criteria)
    end


    # find('projects.acl', 'project_acl', where: :id, eq: packet_id)
    def find(entity_key, repo = nil, **opts)
      criteria = build_criteria(entity_key, repo, **opts)
      find_by_criteria(criteria)
    end

    def find!(entity_key, repo = nil, **opts)
      fail_msg = "does not exist"
      if opts.key?(:cmd_failure)
        fail_msg = opts.delete(:cmd_failure)
      end

      criteria = build_criteria(entity_key, repo, **opts)

      result   = run_cmd!(:find, search: criteria)

      return result if result

      expr = criteria.exprs.first[:expr]
      raise cmd_error(expr.original_attr, fail_msg)
    end

    def find_by_id!(entity_key, id, repo = nil)
      find!(entity_key, repo, single: true, where: :id, eq: id)
    end

    def cmd(name, inputs = {})
      run_cmd(name, inputs)
    end

    def cmd!(name, inputs = {})
      run_cmd!(name, inputs)
    end

    private

    def run_cmd(name, **inputs)
      data[name].run(inputs)
    end

    def run_cmd!(name, **inputs)
      response = run_cmd(name, **inputs)
      raise cmd_error(response) if response.errors?
      response.ok
    end

    def cmd_error(key, msg = nil)
      response = response?(key) ? key : error(key, msg)
      RunError.new(response)
    end
  end
end
