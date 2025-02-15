class PuppetLint::Checks
  def load_data(path, content)
    lexer = PuppetLint::Lexer.new
    PuppetLint::Data.path = path
    begin
      PuppetLint::Data.manifest_lines = content.split("\n", -1)
      PuppetLint::Data.tokens = lexer.tokenise(content)
      PuppetLint::Data.parse_control_comments
    rescue StandardError
      PuppetLint::Data.tokens = []
    end
  end
end

PuppetLint.new_check(:ghostbuster_functions) do
  def manifests
    Dir.glob('./**/manifests/**/*.pp')
  end

  def templates
    Dir.glob('./**/templates/**/*').select { |f| File.file? f }
  end

  def check
    m = path.match(%r{.*/[^/]+/lib/puppet/parser/functions/(.+)\.rb$})
    return if m.nil?

    function_name = m.captures[0]

    manifests.each do |manifest|
      return if File.readlines(manifest).grep(/#{function_name}\(/).size > 0
    end

    templates.each do |template|
      return if File.readlines(template).grep(/scope.function_#{function_name}\(/).size > 0
      return if File.readlines(template).grep(/Puppet::Parser::Functions.function\(:#{function_name}/).size > 0
    end

    notify :warning, {
      message: "Function #{function_name} seems unused",
      line: 1,
      column: 1,
    }
  end
end
