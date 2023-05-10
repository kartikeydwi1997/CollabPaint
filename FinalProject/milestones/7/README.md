# Building Software

- [ ] Instructions on how to build your software should be written in this file
	## Clone the repository
	(Note: We have tested and run this only on Ubuntu/Linux, if you want to run on Mac or Windows please refer to online resources on how you can run GTKD with SDL)
	- Clone the github repository - 
	- If you are not already in the finalproject-d-luminati/ folder then go to the folder by using the following cli command -
		```
		cd finalproject-d-luminati/
		```
	- Go to the PaintProject/ folder with the following command - 
		```
		cd PaintProject/
		```
	## Running the server
	- Open a terminal and go to the PaintProject/ folder.
	- For Linux/Ubuntu users, Run the following command to avoid dub build failures -
		```
			export GDK_BACKEND=x11
		```
	- In the PaintProject/ folder, run the following command to start the server.
		```
		dub run -- --mode server --port <port_number>
		```
	- You can mention any port number in the above command in place of <port_number>.

	## Running the client
	- Open a terminal and go to the PaintProject/ folder.
	- For Linux/Ubuntu users, Run the following command to avoid dub build failures -
		```
		export GDK_BACKEND=x11
		```
	- In the PaintProject/ folder, run the following command to start the client.
		```
		dub run -- --mode client --port <port_number> --ip <ip_address>
		```
	- You need to mention the same port number on which the server is running in place of the <port_number> to run the client and listen to the server messages.
	- You need to mention the IP address of the server in place of <ip_address>.
	- You can start multiple clients using the above command to run a client in a new terminal in the PaintProject/ folder.

	## Running the test cases
	- In the PaintProject/ folder, run the following command to run all the test cases written within the project.
		```
		dub test
		```
	
	## Generating docs
	- Run the below command to generate docs
		```
		dub run adrdox -- -i ./source/ -o docs/
		```

- You should have at a minimum in your project
	- [ ] A dub.json in a root directory
    	- [ ] This should generate a 'release' version of your software
  - [ ] Run your code with the latest version of d-scanner before commiting your code (could be a github action)
  - [ ] (Optional) Run your code with the latest version of clang-tidy  (could be a github action)

*Modify this file to include instructions on how to build and run your software. Specify which platform you are running on. Running your software involves launching a server and connecting at least 2 clients to the server.*
