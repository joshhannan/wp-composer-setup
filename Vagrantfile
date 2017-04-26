# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    # All Vagrant configuration is done here. The most common configuration
    # options are documented and commented below. For a complete reference,
    # please see the online documentation at vagrantup.com.

    # Every Vagrant virtual environment requires a box to build off of.
    config.vm.box = "trusty64"

    # The url from where the 'config.vm.box' box will be fetched if it
    # doesn't already exist on the user's system.
    config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"

    # Provision
    config.vm.provision :shell, :path => ".scripts/bootstrap.sh"

    # Create a private network, which allows host-only access to the machine
    # using a specific IP.
    config.vm.network :private_network, ip: "15.15.15.15"

    # Synced folder
    config.vm.synced_folder "./public_html/", "/vagrant/public_html", id: "vagrant-root", owner: "vagrant", group: "www-data", mount_options: ["dmode=775,fmode=664"]

    # VirtualBox setting
    # Use 2 CPU cores and 3GB system memory
    config.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", "8192"]
        v.customize ["modifyvm", :id, "--cpus", "4"]
    end

    # Host Manager
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true
    config.vm.define 'dietz' do |node|
        node.vm.hostname = 'dietz'
        node.vm.network :private_network, ip: '15.15.15.15'
        node.hostmanager.aliases = %w(dietz.dev)
    end

end