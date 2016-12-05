# docker-cml-examples

Example dockerized computational models

## Requirements

[docker-compose >= 1.8.0](https://docs.docker.com/compose/install/)

[docker >= 1.12.3](https://docs.docker.com/engine/installation/)


## Running the Artificial Anasazi Model

To build the Docker images and run the `netlogo53` service do

```bash
% cd vnc
% ./build.sh
% docker-compose up -d netlogo53
```

Then go to `http://localhost:6901/vnc_auto.html?password=vncpassword` in your web browser. You should see a desktop with a NetLogo shortcut. Click the NetLogo shortcut to start NetLogo and then `File -> Open` the Artificial Anasazi model which should be located at `/root/Documents/projects/articial_anasazi/lhv.nlogo`.
