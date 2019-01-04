module EventFramework
  class Bookmark
    ReadonlyError = Class.new(Error)

    def initialize(name:, database:, read_only: false)
      @name = name
      @database = database
      @read_only = read_only
    end

    def sequence
      row = bookmarks_table.select(:sequence).first(name: name)
      row.nil? ? 0 : row[:sequence]
    end

    def sequence=(value)
      raise ReadonlyError if read_only?

      bookmarks_table.where(name: name).update(sequence: value)
    end

    private

    attr_reader :name, :database

    def read_only?
      @read_only
    end

    def bookmarks_table
      database[:bookmarks]
    end
  end
end
