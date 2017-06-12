require 'spec_helper'

describe 'proxy', :type => :class do
  let(:facts) { {
      :osfamily  => 'Windows'
  } }
  let(:params) {{
      :server_address => 'htt://my-proxy.net',
      :exclude	      => 'localhost, 127.0.0.1'
  }}

  it { should contain_class('template::install').that_comes_before('Class[template::config]') }

  context 'should compile with default values' do
    it {
      is_expected.to compile.with_all_deps
      should contain_class('proxy')
    }
  end

  context 'when trying to install on an unknown server' do
    let(:facts) { {:osfamily => 'Mac'} }

    it { should compile.and_raise_error(/ERROR:: This module will only work on Windows./) }
  end

  context 'when not passing correct values to ensure should fail' do
    let(:params) {{
        :server => 'invalid_server:3128',
    }}

    it { should compile.and_raise_error(/ERROR:: You must specify present or absent/) }
  end

  context 'when not passing example_path should fail' do
    let(:params) {{
        :ensure       => 'present',
        :example_path	=> ''
    }}

    it { should compile.and_raise_error(/ERROR:: You must specify a correct path/) }
  end

end