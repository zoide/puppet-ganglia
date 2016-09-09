
gmond = Facter::Core::Execution.exec('which gmond')
if !gmond.nil?
  ver = Facter::Core::Execution.exec("#{gmond} --version |cut -f 2 -d ' '")
  Facter.add(:ganglia_mond_version) do
    setcode { ver }
  end
end

gmetad = Facter::Core::Execution.exec('which gmetad')

if !gmetad.nil?
  ver = Facter::Core::Execution.exec("#{gmetad} --version |cut -f 2 -d ' '")
  Facter.add(:ganglia_metad_version) do
    setcode { ver }
  end
end
