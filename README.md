# CQPweb-Instabox
Script that sets up and configures an entire CQPweb server installation. For now, see the source code for detailed instructions.


# Quick instructions for setting up a CQPweb server with public key SSH access.
1. Copy the script to your server (virtual or bare metal).

2. Open the script, search for all instances of variables set to `YOUR_INFO_HERE` and change them to appropriate values. Save.

3. Run the script. Don't go away -- it will ask you the occasional question, request you confirm certain things, and provide you with quite a lot of information. In particular, make note of the command to upload your SSH key to the server.

4. Upload your SSH key from your personal computer to the server using the command provided in the previous step.

5. Open the script and in the `SYSTEM CONFIGURATION` section, find the variables currently set to `1` (meaning "to be run") and set them to `2` (meaning "already run") so you don't run them again.

6. Find the variable `SSHKEYSW`, which is set to `0` (meaning "do not run"), and set it to `1` (meaning "to be run). Save.

7. Run the script.

8. Reboot.

You should now have CQPweb running on the IP address the script provides you.


# Quick instructions for setting up a CQPweb server without SSH access.
1. Copy the script to your server (virtual or bare metal).

2. Open the script, search for all instances of variables set to `YOUR_INFO_HERE` and change them to appropriate values.

3. Find `SSHPWDSW` and `SSHKEYSW` and set them both to `0`. Save.

4. Run the script.

5. Reboot.

You should now have CQPweb running on the IP address the script provides you.

# Known issues
While the Postfix mail agent works just fine, the PHP mail module that CQPweb uses does not.
