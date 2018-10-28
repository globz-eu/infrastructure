Feature: Admin user can ssh to node

  Basic configuration of admin user and ssh

  Scenario: Admin opens ssh connection to node
    When an admin with the user name "node_admin" opens a SSH session to a node with the IP "192.168.121.10"
    Then the admin should be logged in to the node
