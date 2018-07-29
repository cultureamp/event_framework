require_relative '../event_framework'

class SchemaDump
  VERSION_REGEX = /
    ^--\sDumped\sfrom\sdatabase\sversion.*$\n
    ^--\sDumped\sby\spg_dump\sversion.*$\n
    ^\n
  /x

  def self.call(database_url, filename:)
    retval = system(
      'pg_dump',
      '--schema-only',
      '--no-owner',
      '--no-privileges',
      '--file',
      filename,
      database_url,
    )

    return unless retval

    contents = File.read(filename)
    contents.gsub!(VERSION_REGEX, '')

    File.open(filename, 'w') { |file| file.puts contents }

    filename
  end
end
