module Appfuel
  module Configuration
    module Search
      # Allow you to access child definitions as if it were a hash.
      # If you add a space separated list of names this will traverse
      # the child hierarchy and return the last name in the list
      #
      # @param name String name or names to search
      # @return Definition | nil
      def [](name)
        find @children, name.to_s.split(" ")
      end

      # Allows you to search child definitions using an array of names
      # instead of a space separated string
      #
      # @param names Array of strings
      # @return Definition | nil
      def search(*names)
        return nil if names.empty?
        find children, names
      end

      protected

      # Recursively locate a child definition in the hierarchy
      #
      # @param child_list Hash
      # @param terms Array of definition keys
      def find(child_list, terms)
        while term = terms.shift
          term = term.to_s
          child_list.each do |(definition_key, definition)|
            next unless definition_key == term
            result = if terms.empty?
                       definition
                     else
                       find(definition.children, terms)
                     end
            return result
          end
        end
      end
    end
  end
end
