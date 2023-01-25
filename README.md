# Autotune Docker Image

_Docker image for running oref0-autotune_

### Information

This image is designed to allow you to run `oref0-autotune` ([docs](http://openaps.readthedocs.io/en/latest/docs/Customize-Iterate/autotune.html)) without needing to have a full copy of oref0 installed to your system. I made this image because oref0 can be quite heavy in terms of filesystem and dependency requirements for someone who wants to use the autotune portion of the system. In addition, the setup process can be quite tricky and time consuming if you're trying to use the autotune feature. By using a docker image for this we can make it simple to run as well as clean up afterwards.

### Building the image

Before building the image, navigate into the directory that includes the `Dockerfile` and **clone the oref0 repository**:
```bash
git clone https://github.com/openaps/oref0
```

Then, you can build this image by running: 
```bash
docker build -t autotune .
```

### Recommended setup

This will run autotune on the Nightscout server `https://mynightscout.azurewebsites.net` starting from June 1, 2018 and ending on June 5, 2018. This should give a good example for most people to start off with. 

```bash
docker run \
    --rm -it \
    --name=autotune \
    -e "START_DATE=2018-06-01" \
    -e "AUTOTUNE_PREFS=--end-date=2018-06-05" \
    -e "NS_HOST=https://mynightscout.azurewebsites.net" \
    -v $PWD/autotune:/data \
    autotune
```

### Getting recommendations

Assuming you created a volume for `/data` the recommendations will be output to `autotune_recommendations.log` in the volume. 

### Volumes

Providing a volume at `/data` in the container will automatically link and use these files and directories. The currently supported files are:
* `autotune_recommendations.log` - the output of autotune (will be overwritten automatically) 
* `profile.json` - file telling autotune what settings your pump uses currently. Instructions for how to make this file can be found [here, scrolling down to step 3](http://openaps.readthedocs.io/en/latest/docs/Customize-Iterate/autotune.html#phase-c-running-autotune-for-suggested-adjustments-without-an-openaps-rig). If you don't specify a profile.json file, one will be generated automatically based on the settings from your Nightscout instance.

```sh
docker run \
    --name=autotune \
    -v /host/path:/data \
    autotune
```

### Running in Nomad

I use an adaptation of this [Nomad job configuration](https://www.nomadproject.io/) to run autotune every week and send me the results.

```
job "autotune" {
    datacenters = ["dc1"]

    type = "batch"

    reschedule {
        attempts       = 5
        interval       = "6h"
        delay          = "30s"
        delay_function = "exponential"
        max_delay      = "30m"
        unlimited      = false
    }

    periodic {
        cron = "0 12 * * 6"
        prohibit_overlap = true
    }

    group "autotune" {
        count = 1

        task "autotune" {
            driver = "docker"

            config {
                image = "ghcr.io/jwoglom/autotune-docker:v1.0.1"
                entrypoint = ["bash"]
                args = [
                    "-c",
                    <<EOF
                        export START_DATE=$(date --date="7 days ago" +%Y-%m-%d) &&
                        /entrypoint.sh &&
                        find /openaps/autotune &&
                        find /data &&
                        cat /openaps/autotune/autotune_recommendations.log &&
                        # do something with the log file (email, slack notification, etc)
                    EOF
                ]
            }

            env {
                NS_HOST = "https://NIGHTSCOUT_URL"
                TIMEZONE = "America/New_York"

            }

            kill_timeout = "60s"

            resources {
                cpu = 100
                memory_max = 300
            }
        }
    }
}
```

### Environment variables

This image works mainly through environment variables. These can be passed through `docker run` by adding `-e` followed by the variable declaration. As an example, adding this to the `docker run` command will set the Nightscout API secret to `hunter2`: `-e "API_SECRET=hunter2"`
The currently supported variables are:
* `NS_HOST` - Required: URL of your Nightscout website to run autotune on. Do not leave a leading slash, it should end with the TLD and nothing more
* `START_DATE` - Required: date of where to run autotune from in YYYY-MM-DD format
* `API_SECRET` - API secret of your Nightscout website
* `AUTOTUNE_PREFS` - Extra command line options to pass along to autotune. More information can be found [below](#additional-autotune-preferences)

### Additional autotune preferences

Autotune permits some additional command line preferences that are not handled by this image. You can specify them under the `AUTOTUNE_PREFS` environment variable

```sh
docker run \
    --name=autotune \
    -e "AUTOTUNE_PREFS=--end-date=2018-06-05" \
    autotune
```

### Troubleshooting

First check the [troubleshooting page](http://openaps.readthedocs.io/en/latest/docs/Customize-Iterate/autotune.html#why-isn-t-it-working-at-all) provided by OpenAPS. Please don't bother the OpenAPS contributors about setup issues since this docker image this is not supported or created by them.
