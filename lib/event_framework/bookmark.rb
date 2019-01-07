module EventFramework
  class Bookmark
    ImmutableBookmarkError = Class.new(Error)
    NoRecordError = Class.new(Error)

    def initialize(name:, database:, immutable: true)
      @name = name
      @database = database
      @immutable = immutable
    end

    def sequence
      bookmarks_table.select(:sequence).first!(name: name)[:sequence]
    rescue Sequel::NoMatchingRow
      raise NoRecordError, "No row exists in bookmarks for #{name}"
    end

    def sequence=(value)
      raise ImmutableBookmarkError if immutable?

      bookmarks_table.where(name: name).update(sequence: value)
    end

    def immutable?
      @immutable
    end

    private

    attr_reader :name, :database

    def bookmarks_table
      database[:bookmarks]
    end
  end
end
