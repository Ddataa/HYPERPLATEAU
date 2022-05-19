const fs = require('fs-extra');
const homedir = require('os').homedir();
const getPath = require("platform-folders");

const HyperdriveServiceClient = require('@hyperspace/hyperdrive/client');
const HyperspaceClient = require('@hyperspace/client');
const Hyperdrive = require('hyperdrive');
const libfuse = require('fuse-shared-library-linux-arm');

module.exports = (function () {

    let client = {};
    let rootKey = {};
    let is_enabled = false;

    return {
        enable: () => (is_enabled = true),
        setup: async () => {
            if (!is_enabled) {
                return null;
            }
            
            const userDirPath = getPath.getDocumentsFolder();
            HyperdrivePath = userDirPath+"/Hyperplateau";
            global.HyperPlateauPath = HyperdrivePath;
            
            DriveStorage = homedir+"/.hyperspace/storage"
            let drive = new Hyperdrive(DriveStorage, null)
            await drive.promises.ready()

            console.log("key:",drive.key);

            let fuseConfig = { 
                rootDriveKey: drive.key.toString('hex'),
                mnt: HyperPlateauPath
            };
             
            let data = JSON.stringify(fuseConfig);
            PathConfig = homedir+"/.hyperspace/config"
            await fs.ensureDir(PathConfig);
            PathFuseConfig = homedir+"/.hyperspace/config/fuse.json"
            fs.writeFileSync(PathFuseConfig, data);
            
            libfuse.isConfigured(function (err, yes) { })

            libfuse.configure(function (err) { console.log(err); })
            client = new HyperdriveServiceClient(opts = 
                {
                mnt: HyperdrivePath,
                key: drive.key
            });
            
            await client.ready()
            console.log(await client.info(HyperPlateauPath))

        },
        mount: async (Path, Key) => {
            if (!is_enabled) {
                return null;
            }
            console.log(" mount hyperdrive ",Path," -> ",Key)
            await fs.ensureDir(Path);
            await client.mount(Path, opts = {
                key: Buffer.from(Key,'hex')
            });
            await client.ready();
            await client.seed(Path,{
                remember: true,
            });
        },
        create: async (Name) => {
            if (!is_enabled) {
                return null;
            }
            NewProject = HyperPlateauPath+"/"+Name

            await client.mount(NewProject);            
            
            await fs.ensureDir(NewProject);
            let info = await client.info(NewProject);
            shareKey = info.key.toString('hex')

            console.log(" create hyperdrive ",Name," -> ",shareKey)
            await client.seed(NewProject,{
                remember: true,
            });

            return shareKey;
        },
        delete: async (Name) => {
            if (!is_enabled) {
                return null;
            }
            DeleteProject = HyperPlateauPath+"/"+Name
            await client.unmount(DeleteProject);
        },
        getShareKey: async (SharePath) => {
            if (!is_enabled) {
                return null;
            }
            SharePath = HyperPlateauPath+SharePath;
            let info = await client.info(SharePath);
            shareKey = info.key.toString('hex')
            return shareKey;
        }
    };
  })();