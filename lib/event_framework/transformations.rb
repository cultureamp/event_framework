require "transproc"

module EventFramework
  module Transformations
    extend Transproc::Registry

    import :deep_symbolize_keys, from: Transproc::HashTransformations
  end
end
