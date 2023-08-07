# unicorn-openfire

This project is is forked from https://github.gamesys.co.uk/client-delivery-platform/community-openfire-chat.

This project builds a Docker container for Openfire Notifications with Gamesys plugins and libraries. The Openfire container has clustering enabled along with Websocket support

There are 2 projects exclusively to add dependencies (only some of our plugins use these. If all plugins use a dependency, the dependency would be in the openfire parent pom instead):
- *unicorn-openfire-third-party-dependencies* (Contains only external libraries)
- *unicorn-openfire-commons* (Contains only internal Gamesys libraries)

These are all the sources of the Openfire project:
1. This project 
    - https://github.gamesys.co.uk/client-delivery-platform/unicorn-openfire-notifications
2. Parent pom 
    - https://github.gamesys.co.uk/PlayerServices/unicorn-openfire-parent-pom.git
3. Dependencies
    - Gamesys: https://github.gamesys.co.uk/client-delivery-platform/chat-openfire-commons/
    - External: https://github.gamesys.co.uk/client-delivery-platform/unicorn-openfire-third-party-dependencies/
4. Plugins
    - https://github.gamesys.co.uk/client-delivery-platform/chat-openfire-reporting-plugin/
    - https://github.gamesys.co.uk/client-delivery-platform/unicorn-openfire-messaging-plugin/
    - https://github.gamesys.co.uk/client-delivery-platform/unicorn-openfire-chat-token-auth-provider/
    - https://github.gamesys.co.uk/PlayerServices/unicorn-openfire-jwt-auth-provider/

## Upgrading Openfire

### Pre-story steps
There are a few steps to take before upgrading our Openfire version.
1. Firstly, take a look at the changes in the change log: http://download.igniterealtime.org/openfire/docs/latest/changelog.html
    - Specifically look for changes to the DB schema - we will need to let Data Warehouse know of any changes as they may use this Data. The SQL schema for 4.5.1 can be seen here: https://github.com/igniterealtime/Openfire/blob/v4.5.1/distribution/src/database/openfire_mysql.sql
2. Raise a support ticket to upload the new Openfire RPM to the YUM repo, and to check the security of the new version.
    - Eg: https://servicedesk.gamesys.co.uk/servicedesk/customer/portal/4/DS-2827

### Upgrading the source code
Once the RPM is uploaded to the Gamesys YUM repo, we can proceed with upgrading Openfire.
1. Upload new version of xmppserver to Artifactory so it can be downloaded by maven (update unicorn-openfire-parent-pom)
    - If the hazelcast version is upgraded in the new xmppserver
        1. Update the hazelcast version in the unicorn-openfire-parent-pom
        2. Update the hazelcast openfire plugin version in unicorn-openfire-notifications (if needed)
2. The Docker image we extend from (see line 1 of `src/main/docker/Dockerfile`) should be the same numeric version as the YUM repo set in `src/main/yum/gamesys_packages.repo`. This is changed if the version of OS is upgraded.
    - e.g: if Docker image is centos:7, YUM repo should be gamesys_packages_el7
3. Change Openfire version in Dockerfile.
4. Hazelcast configuration: compare the openfire config with ours if the hazelcast version is upgraded - `src/main/conf/cluster.xml`
5. Update **unicorn-openfire-parent-pom** properties for all the plugins that need to be updated. Try to be careful and if the new plugin needed is provided by Openfire add the tag `<provided>`
    1. If **unicorn-openfire-commons** is updated as part of the upgrade, you will need to increase its version in the properties of unicorn-openfire-parent-pom (version bumping - since some of the plugins are dependent on his repo).
    2. If there are changes in **unicorn-openfire-parent-pom**, all the openfire plugins using this parent will need to use the new version.
6. Build in the console and look for errors inside the container logs: `mvn clean install docker:build docker:push`
7. Deploy to integration using Control Centre. Test and verify errors in Splunk
    - If there are changes to the Openfire DB schema (see pre-story steps), this will change the Liquibase checksum of patch `01-create-schema.xml`. When you deploy to integration, you will see a 'Liquibase: Validation Failed:' error which will show the new checksum. Go to patch `01-create-schema.xml` and replace the existing checksum inside the `<validCheckSum>` tag with the new checksum. This will ensure that validation is successful and the SQL changes in the OF schema are executed.
8. Merge and build
    - If only pom changes are done (in any project), the GoCD build does not trigger automatically - you will need to do it manually.
    - You will need to build all the plugins using the updated dependencies.
    - There are 14 sources to be built. It is easy to miss one. Track your progress here: https://docs.google.com/spreadsheets/d/1WaIgHf28uluM0WAChVv1VredQfO1_1mvh2clRK1LY8E/edit?usp=sharing
    - Order:
        1. If **unicorn-openfire-commons** was modified, this is the first one you need to merge as you need to change the snapshot for the production tag in *unicorn-openfire-parent-pom*
        2. **unicorn-openfire-parent-pom** Remember to remove the SNAPSHOTS
        3. Built the rest of the openfire plugins
        4. Update **unicorn-openfire-notifications** versions (No SNAPSHOT should be there at this point)
9. Load test (see the below section)
10. Full regression on the artifact build from GoCD without SNAPSHOTs in any of the poms

#### Potential infrastructure changes
- Check that the latest version is in their maven repository: https://igniterealtime.org/repo/org/igniterealtime/openfire/xmppserver/
  - If it isn't, it may be worth raising an issue with OF, like so: https://discourse.igniterealtime.org/t/latest-release-of-xmppserver-not-published-in-maven-repo/87538
- We also had to add another Ignite Realtime dependency (tinder)
  - Source was: https://igniterealtime.org/archiva/repository/maven/org/igniterealtime/tinder/
  - Target was: https://artifactory.gamesys.co.uk/artifactory/gamesys-unicorn-maven-release-virtual/org/igniterealtime/tinder/
  - Support ticket: https://servicedesk.gamesys.co.uk/servicedesk/customer/portal/4/DS-2894

## Load test
You can find detailed information here: https://confluence.gamesys.co.uk/display/TEAMCHA/Community+Team+Starter+Page#CommunityTeamStarterPage-FoxyScript-Load&AutomatedTesting

To execute them in the inception space:
1. `ssh community@community-chat-01.pscommunity.pgt.gaia`
2. `cd tests/openfire/copy-foxy`
    Will need to copy the openfire project(s) to this directory to get the latest changes

Disable some logs before running the load test:
- Verify the variable `gameysys.reporting.omnidata.enabled` is false so no data is sent to google.
- The reporting plugin should be disabled too.:

It is recommended to have four processes running so that the load test is valid. That will increase the load on the server tested as different processors are sending requests to the server in parallel.
- 3 slaves: `java -jar target/foxy-1.0.0-SNAPSHOT.jar slave`
- 1 master: `java -jar target/foxy-1.0.0-SNAPSHOT.jar master --host jackpotjoy.chat.ppc1.pgt01.gamesysgames.com --speed 100 --report target/report_host_info.json --await ~/Documents/projects/community/tools/community-tools-foxy-feeder/foxy_feeder/host_info_scenario.txt`

You should see that the cluster has 4 members. For example:
Members {size:4, ver:4} [
	Member [10.124.132.8]:5701 - 0a40af1c-959f-4863-bbae-78ef5de3046e
	Member [10.124.132.8]:5702 - f6944e5d-bea7-475e-857b-0a4477a9d013
	Member [10.124.132.8]:5703 - 081ecc8e-61d7-4fd0-8aac-c42bb665871c
	Member [10.124.132.8]:5704 - abb9536c-5f67-4cc9-8a4e-b64724edf3b5 this
]

These commands create reports in the path specified on --report. 
To verify that everything is as expected, look at the load and the memory in Grafana (https://graphite.pgt01.gamesysgames.com/). Search for 'ERROR' in the generated reports and correlate them with Splunk.

### Example load test results
An old load test is documented here: https://confluence.gamesys.co.uk/pages/viewpage.action?spaceKey=TEAMCHA&title=GTECH-5146%3A+Upgrade+to+Openfire+4.2.3

