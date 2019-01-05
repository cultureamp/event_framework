module EventFramework
  class Bookmark
    ReadonlyError = Class.new(Error)
    NoRecordError = Class.new(Error)

    def initialize(name:, database:, read_only: false)
      @name = name
      @database = database
      @read_only = read_only
    end

    def sequence
      bookmarks_table.select(:sequence).first!(name: name)[:sequence]
    rescue Sequel::NoMatchingRow
      raise NoRecordError, "No row exists in bookmarks for #{name}"
    end

    def sequence=(value)
      raise ReadonlyError if read_only?

      bookmarks_table.where(name: name).update(sequence: value)
    end

    def read_only?
      @read_only
    end

    private

    attr_reader :name, :database

    def bookmarks_table
      database[:bookmarks]
    end
  end
end
