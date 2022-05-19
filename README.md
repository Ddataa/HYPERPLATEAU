# hyperplateau

Tool based on hypercore protocol, plateau, do•doc and adc-core.
See [hypercore-protocol](https://hypercore-protocol.org/) & [plateau](https://github.com/l-atelier-des-chercheurs/plateau) for more informations.

to be installed on a clean debian stable VM or small machine SBC
execute command below to install and configure plateau with Hyperdrive service (and web server + wifi hotspot)
'wget -qO - https://hyperplateau.ddataa.org/setup.sh | sudo bash'

The [setup](https://hyperplateau.ddataa.org/setup.sh) [scripts](https://git.ddataa.org/DDATAA/HYPERPLATEAU/src/branch/master/setup/start.sh) will 
- clone this repository
- install dependencies (nodejs npm minimal necessary packages)
- configure the system (hostname, services, update, upgrade)
- compile & launch plateau
- configure & launch hyperspace daemon
- configure & launch caddy web server & reverse proxy
- on raspberry pi set wifi hotspot & specific dependencies & configuration

[Hyperdrive-service](https://github.com/hyperspace-org/hyperdrive-service) is a p2p distributed file system. Hyperplateau is hyperdrive + plateau.

You can find your plateau projects in your user Document folder and you can share them to other plateau instance available locally or via internet.

In your project options you will find a "share" button to view a code to connect other plateau instance you want to share your project with.
Then this code might be used to create a new project on another plateau instance. The newly copied project will be only readable.


