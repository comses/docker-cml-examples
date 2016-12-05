# docker-cml-examples

Example dockerized computational models

## Requirements

```
docker-compose >= 1.8.0
docker >= 1.12.3
```

## Running the Artificial Anasazi Model

To build the Docker images and run the `netlogo53` service do

```bash
cd vnc
./build.sh
docker-compose up netlogo53
```

Then go to `http://localhost:6901/vnc_auto.html?password=vncpassword` in your web browser. You should see a desktop with a NetLogo shortcut. Click the shortcut open NetLogo. Once in NetLogo open the Artificial Anasazi model. It should be at `/root/Documents/projects/articial_anasazi/lhv.nlogo`.
