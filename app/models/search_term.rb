# `%` and `_` are wildcards to SQL and letters to the person typing them.
# `matching` builds the ESCAPE clause with them so neither is forgotten.
class SearchTerm
  ESCAPE = "\\".freeze
  WILDCARDS = /[\\%_]/

  def self.matching(*columns)
    columns.map { |column| "#{column} LIKE :term ESCAPE '#{ESCAPE}'" }.join(" OR ")
  end

  def initialize(typed)
    @typed = typed.to_s.strip
  end

  def blank?
    @typed.empty?
  end

  def anywhere
    "%#{escaped}%"
  end

  private
    def escaped
      @typed.gsub(WILDCARDS) { |char| "#{ESCAPE}#{char}" }
    end
end
