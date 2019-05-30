# CQPweb-Instabox
Script that sets up and configures an entire [CQPweb](http://cwb.sourceforge.net/cqpweb.php) server installation. 

# Instructions for setting up your own personal CQPweb In A Box.
As of v. 63, CQPweb-Instabox is even easier to use -- it allows you to perform one of four pre-defined install types, plus a default install that includes whatever software and configuration is set to `1` in the script file (this allows you to customize your preferences down to the last detail and then deploy this install as many times as you wish).

To install CQPweb-Instabox, run one of the following:

* `./cqpweb-instabox.sh vm`: Set up a basic CWB and CQPweb install in a virtual machine.
* `./cqpweb-instabox.sh vmdeluxe`: Set up a CWB and CQPweb install, plus a broad selection of linguistics software, in a virtual machine.
* `./cqpweb-instabox.sh server`: Set up CWB, CQPweb and basic server software on a server (headless or GUI).
* `./cqpweb-instabox.sh serverdeluxe`: Set up CWB, CQPweb and a suite of server-related software on a server (headless or GUI).
* `./cqpweb-instabox.sh default`: Set up and configure all software specified by the user in the script's configuration section.

Note that the two server options, and possibly the `default` option (depending on your settings), install and configure SSH public key access. This requires an additional step -- after the main install, you must upload your public SSH key to the server and then run this script again, this time with the `ssh` argument, as follows:

* `./cqpweb-instabox.sh ssh`

Also note that while most installation options only take a few minutes, the `vmdeluxe` option can take several hours due to the fact that it downloads and complies a great many R packages.

# Known issues
While the Postfix mail agent that the `server` and `serverdeluxe` options install works just fine (try it with the `testmail-postfix.sh` script located in `~/bin`!), the PHP mail module that CQPweb uses does not work.
