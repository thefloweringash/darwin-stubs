#!/usr/bin/env ruby

require 'psych'

def framework_path(install_name)
  return install_name if install_name.start_with?("@")

  case
  when (m = %r{/System/Library/(?:|Private)Frameworks/([^/]+).framework/(.+)}.match(install_name))
    framework_name, suffix = m.captures
    "@#{framework_name}@/Library/Frameworks/#{framework_name}.framework/#{suffix}"
  when install_name == "/usr/lib/libobjc.A.dylib"
    "@libobjc@/lib/libobjc.A.dylib"
  when install_name == "/usr/lib/libcharset.1.dylib"
    "@libcharset@/lib/libcharset.1.dylib"
  when install_name == "/usr/lib/libnetwork.dylib"
    "@libnetwork@/lib/libnetwork.dylib"
  when (m = %r{/usr/lib/system/(.+)}.match(install_name))
    lib, = m.captures
    "@Libsystem@/lib/system/#{lib}"
  else
    warn "Unhandled re-export path: #{install_name}"
    install_name
  end
end

def rewrite(fpath)
  changed = false

  in_stream = File.read(fpath)
  ast = Psych.parse_stream(in_stream)

  ast.grep(Psych::Nodes::Mapping).each do |node|
    node.children.each_slice(2) do |k, v|
      if k.value == 're-exports'
        changed = true
        v.children.each do |re_export|
          re_export.value = framework_path(re_export.value)
        end
      end

      if k.value == 'reexported-libraries'
        v.children.each do |re_export|
          re_export.children.each_slice(2) do |ck, cv|
            if ck.value == 'libraries'
              cv.children.each do |lib|
                old_value = lib.value
                lib.value = framework_path(lib.value)
                changed ||= old_value != lib.value
              end
            end
          end
        end
      end
    end
  end

  File.write(fpath, ast.yaml) if changed
end

Dir[ARGV.first].each { |f| rewrite(f) }
