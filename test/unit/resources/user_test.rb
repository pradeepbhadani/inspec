require "helper"
require "inspec/resource"
require "inspec/resources/users"
require "inspec/resources/command"

describe "Inspec::Resources::User" do

  # ubuntu
  it "read user on ubuntu" do
    resource = MockLoader.new(:ubuntu).load_resource("user", "root")
    _(resource.exists?).must_equal true
    _(resource.group).must_equal "root"
    _(resource.groups).must_equal ["root"]
    _(resource.home).must_equal "/root"
    _(resource.shell).must_equal "/bin/bash"
    _(resource.mindays).must_equal 0
    _(resource.maxdays).must_equal 99999
    _(resource.warndays).must_equal 7
  end

  # ubuntu 14.04 test with ldap user
  it "read user on ubuntu" do
    resource = MockLoader.new(:ubuntu).load_resource("user", "jfolmer")
    _(resource.exists?).must_equal true
    _(resource.group).must_equal "domain users"
    _(resource.groups).must_equal ["domain users", "domain admins", "denied rodc password replication group"]
    _(resource.home).must_equal "/jfolmer"
    _(resource.shell).must_equal "/bin/bash"
    _(resource.mindays).must_equal 0
    _(resource.maxdays).must_equal 99999
    _(resource.warndays).must_equal 7
  end

  # serverspec compatibility tests (do not test matcher)
  it "returns deprecation notices" do
    resource = MockLoader.new(:ubuntu).load_resource("user", "root")

    expect_deprecation(:resource_user_serverspec_compat) do
      _(resource.has_uid?(0)).must_equal true
    end

    expect_deprecation(:resource_user_serverspec_compat) do
      _(resource.has_home_directory?("/root")).must_equal true
    end

    expect_deprecation(:resource_user_serverspec_compat) do
      _(resource.has_login_shell?("/bin/bash")).must_equal true
    end

    expect_deprecation(:resource_user_serverspec_compat) do
      _(resource.minimum_days_between_password_change).must_equal 0
    end

    expect_deprecation(:resource_user_serverspec_compat) do
      _(resource.maximum_days_between_password_change).must_equal 99999
    end

    expect_deprecation(:resource_user_serverspec_compat) do
      _(proc { resource.has_authorized_key?("abc") }).must_raise NotImplementedError
    end
  end

  it "handles a password that has never changed" do
    resource = quick_resource(:user, :linux) do |cmd|
      cmd.strip!
      case cmd
      when "chage -l" then
        string <<~EOM
          Last password change                                  : never
          Password expires                                      : never
          Password inactive                                     : never
          Account expires                                               : never
          Minimum number of days between password change                : 0
          Maximum number of days between password change                : 99999
          Number of days of warning before password expires     : 7
        EOM
      else
        string "" # doesn't matter... they don't error for some reason
      end
    end

    _(resource.passwordage).must_be_nil
  end

  it "read user on centos7" do
    resource = MockLoader.new(:centos7).load_resource("user", "root")
    _(resource.exists?).must_equal true
    _(resource.group).must_equal "root"
    _(resource.groups).must_equal ["root"]
    _(resource.home).must_equal "/root"
    _(resource.shell).must_equal "/bin/bash"
    _(resource.mindays).must_equal 0
    _(resource.maxdays).must_equal 99999
    _(resource.warndays).must_equal 7
    _(resource.passwordage).must_be_kind_of Integer # changes every day
  end

  it "read user on centos7" do
    resource = MockLoader.new(:wrlinux).load_resource("user", "root")
    _(resource.exists?).must_equal true
    _(resource.group).must_equal "root"
    _(resource.groups).must_equal ["root"]
    _(resource.home).must_equal "/root"
    _(resource.shell).must_equal "/bin/bash"
    _(resource.mindays).must_equal 0
    _(resource.maxdays).must_equal 99999
    _(resource.warndays).must_equal 7
  end

  it "read user on hpux" do
    resource = MockLoader.new(:hpux).load_resource("user", "root")
    _(resource.home).must_equal "/"
    _(resource.shell).must_equal "/sbin/sh"
  end

  it "read user on freebsd" do
    resource = MockLoader.new(:freebsd11).load_resource("user", "fzipi")
    _(resource.exists?).must_equal true
    _(resource.group).must_equal "fzipi"
    _(resource.groups).must_equal %w{fzipi wheel users}
    _(resource.home).must_equal "/home/fzipi"
    _(resource.shell).must_equal "/usr/local/bin/bash"
    _(resource.mindays).must_be_nil
    _(resource.maxdays).must_be_nil
    _(resource.warndays).must_be_nil
  end

  it "read user on OSX" do
    resource = MockLoader.new(:macos10_10).load_resource("user", "chartmann")
    _(resource.exists?).must_equal true
    _(resource.group).must_equal "staff"
    _(resource.groups).must_equal ["staff", "com.apple.sharepoint.group.1", "everyone"]
    _(resource.home).must_equal "/Users/chartmann"
    _(resource.shell).must_equal "/bin/zsh"
    _(resource.mindays).must_be_nil
    _(resource.maxdays).must_be_nil
    _(resource.warndays).must_be_nil
  end

  it "read administrator user on Windows" do
    resource = MockLoader.new(:windows).load_resource("user", "Administrator")
    _(resource.uid).wont_be_nil
    _(resource.exists?).must_equal true
    _(resource.group).must_be_nil
    _(resource.groups).must_equal %w{Administrators Users}
    _(resource.home).wont_be_nil
    _(resource.shell).must_be_nil
    _(resource.mindays).wont_be_nil
    _(resource.maxdays).wont_be_nil
    _(resource.warndays).must_be_nil
    _(resource.disabled?).must_equal false
    _(resource.lastlogin).must_equal "11/14/2019 21:03:09"
  end

  it "read guest user on Windows" do
    resource = MockLoader.new(:windows).load_resource("user", "Guest")
    _(resource.uid).wont_be_nil
    _(resource.exists?).must_equal true
    _(resource.group).must_be_nil
    _(resource.groups).must_equal ["Users"]
    _(resource.home).wont_be_nil
    _(resource.shell).must_be_nil
    _(resource.mindays).wont_be_nil
    _(resource.maxdays).wont_be_nil
    _(resource.warndays).must_be_nil
    _(resource.disabled?).must_equal true
    _(resource.lastlogin).must_be_nil
  end

  it "read disabled user on Windows" do
    resource = MockLoader.new(:windows).load_resource("user", "Guest")
    _(resource.uid).wont_be_nil
    _(resource.exists?).must_equal true
    _(resource.disabled?).must_equal true
    _(resource.lastlogin).must_be_nil
  end

  it "read user on undefined os" do
    resource = MockLoader.new(:undefined).load_resource("user", "root")
    _(resource.exists?).must_equal false
    _(resource.group).must_be_nil
    _(resource.groups).must_be_nil
    _(resource.home).must_be_nil
    _(resource.shell).must_be_nil
    _(resource.mindays).must_be_nil
    _(resource.maxdays).must_be_nil
    _(resource.warndays).must_be_nil
  end
end
