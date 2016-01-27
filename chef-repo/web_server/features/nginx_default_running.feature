Feature: NGINX is running and default page can be accessed

  Basic configuration of NGINX has been provisioned

  Scenario: Admin visits root page of server
    Given a url "http://192.168.121.10/"
    When an admin browses to the URL
    Then the admin should see "Welcome to nginx!"