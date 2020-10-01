#!/usr/bin/env ruby

require 'psych'

def rewrite(fpath)
  changed = false

  in_stream = File.read(fpath)
  ast = Psych.parse_stream(in_stream)

  ast.grep(Psych::Nodes::Sequence).each do |node|
    next unless node.children.all? { |x| x.is_a?(Psych::Nodes::Scalar) }
    if node.children.any? { |x| x.value == "x86_64" }
      changed = true
      node.children.push(Psych::Nodes::Scalar.new("aarch64"))
    end
  end

  File.write(fpath, ast.yaml) if changed
end

Dir[ARGV.first].each { |f| rewrite(f) }
