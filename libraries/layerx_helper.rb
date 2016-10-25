module LayerxHelper
  def self.in_path?(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        exe if File.executable?(exe) && !File.directory?(exe)
      }
    end
    nil
  end
end
