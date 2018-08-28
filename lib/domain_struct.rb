module EventFramework
  class DomainStruct < Dry::Struct
    transform_keys(&:to_sym)
  end
end
