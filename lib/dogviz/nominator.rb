module Dogviz
  module Nominator
    def nominate(names_to_nominees)
      names_to_nominees.each { |name, nominee|
        define_singleton_method sanitized_name(name) do
          nominee
        end
      }
    end

    def nominate_from(nominee_nominator, *nominee_names)
      nominee_names.each { |name|
        accessor_sym = name.to_s.to_sym
        nominate accessor_sym => nominee_nominator.send(accessor_sym)
      }
    end

    private

    def sanitized_name(name)
      return name if name.is_a?(Symbol)
      name.to_s.gsub(/\s/, '_').downcase
    end
    
  end
end