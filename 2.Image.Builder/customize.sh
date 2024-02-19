#!/bin/bash -x

binPaths=""
binDirectory="/usr/local/bin"
cd $binDirectory

aaaProfile="/etc/profile.d/aaa.sh"
touch $aaaProfile

source /tmp/functions.sh

echo "Customize (Start): Image Build Parameters"
buildConfig=$(echo $buildConfigEncoded | base64 -d)
machineType=$(echo $buildConfig | jq -r .machineType)
gpuProvider=$(echo $buildConfig | jq -r .gpuProvider)
binStorageHost=$(echo $buildConfig | jq -r .binStorage.host)
binStorageAuth=$(echo $buildConfig | jq -r .binStorage.auth)
adminUsername=$(echo $buildConfig | jq -r .dataPlatform.admin.username)
adminPassword=$(echo $buildConfig | jq -r .dataPlatform.admin.password)
mongoDBUsername=$(echo $buildConfig | jq -r .dataPlatform.mongoDB.username)
mongoDBPassword=$(echo $buildConfig | jq -r .dataPlatform.mongoDB.password)
mongoDBHost=$(echo $buildConfig | jq -r .dataPlatform.mongoDB.host)
mongoDBPort=$(echo $buildConfig | jq -r .dataPlatform.mongoDB.port)
postgreSQLUsername=$(echo $buildConfig | jq -r .dataPlatform.postgreSQL.username)
postgreSQLPassword=$(echo $buildConfig | jq -r .dataPlatform.postgreSQL.password)
postgreSQLHost=$(echo $buildConfig | jq -r .dataPlatform.postgreSQL.host)
postgreSQLPort=$(echo $buildConfig | jq -r .dataPlatform.postgreSQL.port)
renderEngines=$(echo $buildConfig | jq -c .renderEngines)
enableCosmosDB=false
if [ "$mongoDBHost" == "" ]; then
  mongoDBHost=$(hostname)
else
  enableCosmosDB=true
fi
echo "Machine Type: $machineType"
echo "GPU Provider: $gpuProvider"
echo "Admin Username: $adminUsername"
echo "Admin Password: $adminPassword"
echo "Enable Cosmos DB: $enableCosmosDB"
echo "MongoDB Username: $mongoDBUsername"
echo "MongoDB Password: $mongoDBPassword"
echo "MongoDB Host: $mongoDBHost"
echo "MongoDB Port: $mongoDBPort"
echo "PostgreSQL Host: $postgreSQLHost"
echo "PostgreSQL Port: $postgreSQLPort"
echo "PostgreSQL Username: $postgreSQLUsername"
echo "PostgreSQL Password: $postgreSQLPassword"
echo "Render Engines: $renderEngines"
echo "Customize (End): Image Build Parameters"

echo "Customize (Start): Image Build Platform"
dnf -y install kernel-devel-$(uname -r)
if [ $machineType == Workstation ]; then
  echo "Customize (Start): Image Build Platform (Workstation)"
  dnf -y group install workstation
  dnf -y module install nodejs
  echo "Customize (End): Image Build Platform (Workstation)"
fi
echo "Customize (End): Image Build Platform"

if [ $machineType == Storage ]; then
  echo "Customize (Start): NVIDIA OFED"
  processType="mellanox-ofed"
  installFile="MLNX_OFED_LINUX-23.10-1.1.9.0-rhel8.9-x86_64.tgz"
  downloadUrl="$binStorageHost/NVIDIA/OFED/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  tar -xzf $installFile
  dnf -y install kernel-modules-extra kernel-rpm-macros rpm-build libtool gcc-gfortran pciutils tcl tk
  RunProcess "./MLNX_OFED*/mlnxofedinstall --without-fw-update --add-kernel-support --skip-repo --force" $binDirectory/$processType
  echo "Customize (End): NVIDIA OFED"
fi

if [ "$gpuProvider" == NVIDIA ]; then
  echo "Customize (Start): NVIDIA GPU (GRID)"
  processType="nvidia-gpu-grid"
  installFile="$processType.run"
  downloadUrl="https://go.microsoft.com/fwlink/?linkid=874272"
  curl -o $installFile -L $downloadUrl
  chmod +x $installFile
  dnf -y install mesa-vulkan-drivers libglvnd-devel
  RunProcess "./$installFile --silent" $binDirectory/$processType
  echo "Customize (End): NVIDIA GPU (GRID)"

  echo "Customize (Start): NVIDIA GPU (CUDA)"
  dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
  dnf -y install cuda
  echo "Customize (End): NVIDIA GPU (CUDA)"

  echo "Customize (Start): NVIDIA OptiX"
  versionInfo="8.0.0"
  processType="nvidia-optix"
  installFile="NVIDIA-OptiX-SDK-$versionInfo-linux64-x86_64.sh"
  downloadUrl="$binStorageHost/NVIDIA/OptiX/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  chmod +x $installFile
  installPath="$binDirectory/$processType/$versionInfo"
  mkdir -p $installPath
  RunProcess "./$installFile --skip-license --prefix=$installPath" $binDirectory/$processType-1
  buildDirectory="$installPath/build"
  mkdir -p $buildDirectory
  dnf -y install mesa-libGL
  dnf -y install mesa-libGL-devel
  dnf -y install libXrandr-devel
  dnf -y install libXinerama-devel
  dnf -y install libXcursor-devel
  RunProcess "cmake -B $buildDirectory -S $installPath/SDK" $binDirectory/$processType-2
  RunProcess "make -C $buildDirectory" $binDirectory/$processType-3
  binPaths="$binPaths:$buildDirectory/bin"
  echo "Customize (End): NVIDIA OptiX"
fi

if [[ $machineType == Storage || $machineType == Scheduler ]]; then
  echo "Customize (Start): Azure CLI"
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  dnf -y install https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
  dnf -y install azure-cli
  echo "Customize (End): Azure CLI"
fi

if [[ $renderEngines == *PBRT* ]]; then
  echo "Customize (Start): PBRT"
  versionInfo="v4"
  processType="pbrt"
  installPath="/usr/local/pbrt"
  mkdir -p $installPath
  dnf -y install mesa-libGL-devel
  dnf -y install libXrandr-devel
  dnf -y install libXinerama-devel
  dnf -y install libXcursor-devel
  dnf -y install libXi-devel
  RunProcess "git clone --recursive https://github.com/mmp/$processType-$versionInfo.git" $binDirectory/$processType-1
  RunProcess "cmake -B $installPath -S $binDirectory/$processType-$versionInfo" $binDirectory/$processType-2
  RunProcess "make -C $installPath" $binDirectory/$processType-3
  binPaths="$binPaths:$installPath"
  echo "Customize (End): PBRT"
fi

if [[ $renderEngines == *Blender* ]]; then
  echo "Customize (Start): Blender"
  versionInfo="4.0.2"
  versionType="linux-x64"
  processType="blender"
  installPath="/usr/local/$processType"
  installFile="$processType-$versionInfo-$versionType.tar.xz"
  downloadUrl="$binStorageHost/Blender/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  tar -xJf $installFile
  dnf -y install mesa-libGL
  dnf -y install libXxf86vm
  dnf -y install libXfixes
  dnf -y install libXi
  dnf -y install libSM
  mkdir -p $installPath
  mv $processType-$versionInfo-$versionType/* $installPath
  binPaths="$binPaths:$installPath"
  echo "Customize (End): Blender"
fi

if [[ $renderEngines == *Maya* ]]; then
  echo "Customize (Start): Maya"
  versionInfo="2024_0_1"
  processType="autodesk-maya"
  installFile="Autodesk_Maya_${versionInfo}_Update_Linux_64bit.tgz"
  downloadUrl="$binStorageHost/Maya/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  mkdir -p $processType
  tar -xzf $installFile -C $processType
  dnf -y install mesa-libGL
  dnf -y install mesa-libGLU
  dnf -y install alsa-lib
  dnf -y install libXxf86vm
  dnf -y install libXmu
  dnf -y install libXpm
  dnf -y install libnsl
  dnf -y install gtk3
  RunProcess "./$processType/Setup --silent" $binDirectory/$processType
  binPaths="$binPaths:/usr/autodesk/maya/bin"
  echo "Customize (End): Maya"
fi

if [[ $renderEngines == *Houdini* ]]; then
  echo "Customize (Start): Houdini"
  versionInfo="20.0.506"
  versionEULA="2021-10-13"
  processType="houdini"
  installFile="$processType-$versionInfo-linux_x86_64_gcc11.2.tar.gz"
  downloadUrl="$binStorageHost/Houdini/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  tar -xzf $installFile
  [ $machineType == Workstation ] && desktopMenus="--install-menus" || desktopMenus="--no-install-menus"
  [[ $renderEngines == *Maya* ]] && mayaPlugIn="--install-engine-maya" || mayaPlugIn="--no-install-engine-maya"
  dnf -y install mesa-libGL
  dnf -y install libXcomposite
  dnf -y install libXdamage
  dnf -y install libXrandr
  dnf -y install libXcursor
  dnf -y install libXi
  dnf -y install libXtst
  dnf -y install libXScrnSaver
  dnf -y install alsa-lib
  dnf -y install libnsl
  dnf -y install avahi
  RunProcess "./houdini*/houdini.install --auto-install --make-dir --no-install-license --accept-EULA $versionEULA $desktopMenus $mayaPlugIn" $binDirectory/$processType
  binPaths="$binPaths:/opt/hfs$versionInfo/bin"
  echo "Customize (End): Houdini"
fi

if [ $machineType == Scheduler ]; then
  echo "Customize (Start): NFS Server"
  systemctl --now enable nfs-server
  echo "Customize (End): NFS Server"
fi

if [ $machineType != Storage ]; then
  versionInfo="10.2.0.10"
  installRoot="/deadline"
  databaseName="deadline10db"
  binPathScheduler="$installRoot/bin"

  echo "Customize (Start): Deadline Download"
  installFile="Deadline-$versionInfo-linux-installers.tar"
  installPath=$(echo ${installFile%.tar})
  downloadUrl="$binStorageHost/Deadline/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  mkdir -p $installPath
  tar -xzf $installFile -C $installPath
  echo "Customize (End): Deadline Download"

  if [ $machineType == Scheduler ]; then
    if [ $enableCosmosDB != true ]; then
      echo "Customize (Start): Mongo DB Service"
      if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
        echo never > /sys/kernel/mm/transparent_hugepage/enabled
      fi
      repoPath="/etc/yum.repos.d/mongodb.repo"
      echo "[mongodb-org-5.0]" > $repoPath
      echo "name=MongoDB" >> $repoPath
      echo "baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/5.0/x86_64/" >> $repoPath
      echo "gpgcheck=1" >> $repoPath
      echo "enabled=1" >> $repoPath
      echo "gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc" >> $repoPath
      dnf -y install mongodb-org
      configFile="/etc/mongod.conf"
      sed -i "s/bindIp: 127.0.0.1/bindIp: 0.0.0.0/" $configFile
      sed -i "/bindIp: 0.0.0.0/a\  tls:" $configFile
      sed -i "/tls:/a\    mode: disabled" $configFile
      systemctl --now enable mongod
      echo "Customize (End): Mongo DB Service"

      echo "Customize (Start): Mongo DB Users"
      processType="mongo-create-admin-user"
      mongoScript="$processType.js"
      echo "use admin" > $mongoScript
      echo "db.createUser({" >> $mongoScript
      echo "  user: \"$adminUsername\"," >> $mongoScript
      echo "  pwd: \"$adminPassword\"," >> $mongoScript
      echo "  roles: [" >> $mongoScript
      echo "    { role: \"userAdminAnyDatabase\", db: \"admin\" }," >> $mongoScript
      echo "    { role: \"readWriteAnyDatabase\", db: \"admin\" }" >> $mongoScript
      echo "  ]" >> $mongoScript
      echo "})" >> $mongoScript
      RunProcess "mongosh $mongoScript" $binDirectory/$processType

      # sed -i "s/#security:/security:/" $configFile
      # sed -i "/security:/a\  authorization: enabled" $configFile
      # systemctl restart mongod

      processType="mongo-create-database-user"
      mongoScript="$processType.js"
      echo "db = db.getSiblingDB(\"$databaseName\");" > $mongoScript
      echo "db.createUser({" >> $mongoScript
      echo "  user: \"$mongoDBUsername\"," >> $mongoScript
      echo "  pwd: \"$mongoDBPassword\"," >> $mongoScript
      echo "  roles: [" >> $mongoScript
      echo "    { role: \"dbOwner\", db: \"$databaseName\" }" >> $mongoScript
      echo "  ]" >> $mongoScript
      echo "})" >> $mongoScript
      # RunProcess "mongosh --authenticationDatabase admin -u $adminUsername -p $adminPassword $mongoScript" $binDirectory/$processType
      RunProcess "mongosh $mongoScript" $binDirectory/$processType
      echo "Customize (End): Mongo DB Users"
    fi

    echo "Customize (Start): Deadline Server"
    processType="deadline-repository"
    installFile="DeadlineRepository-$versionInfo-linux-x64-installer.run"
    export DB_PASSWORD=$mongoDBPassword
    if [ $enableCosmosDB == true ]; then
      mongoDBCertFile=cosmos-mongo-db
      openssl s_client -connect $mongoDBHost:$mongoDBPort < /dev/null | openssl x509 -outform pem > $mongoDBCertFile.pem
      openssl pkcs12 -export -nokeys -passout pass:$mongoDBPassword -in $mongoDBCertFile.pem -out $mongoDBCertFile.pfx
      RunProcess "$installPath/$installFile --mode unattended --dbLicenseAcceptance accept --prefix $installRoot --dbhost $mongoDBHost --dbport $mongoDBPort --dbname $databaseName --dbuser $mongoDBUsername --dbpassword env:DB_PASSWORD --dbauth true --installmongodb false --dbreplicaset globaldb --dbssl true --dbclientcert $(pwd)/$mongoDBCertFile.pfx --dbcertpass env:DB_CERT_PASSWORD" $binDirectory/$processType
    else
      RunProcess "$installPath/$installFile --mode unattended --dbLicenseAcceptance accept --prefix $installRoot --dbhost $mongoDBHost --dbport $mongoDBPort --dbname $databaseName --dbuser $mongoDBUsername --dbpassword env:DB_PASSWORD --dbauth true --installmongodb false" $binDirectory/$processType
    fi
    mv /tmp/installbuilder_installer.log $binDirectory/deadline-repository.log
    echo "$installRoot *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    exportfs -r
    echo "Customize (End): Deadline Server"
  fi

  echo "Customize (Start): Deadline Client"
  processType="deadline-client"
  installFile="DeadlineClient-$versionInfo-linux-x64-installer.run"
  installArgs="--mode unattended --prefix $installRoot"
  if [ $machineType == Scheduler ]; then
    installArgs="$installArgs --slavestartup false --launcherdaemon false"
  else
    [ $machineType == Farm ] && workerStartup="true" || workerStartup="false"
    installArgs="$installArgs --slavestartup $workerStartup --launcherdaemon true"
  fi
  RunProcess "$installPath/$installFile $installArgs" $binDirectory/$processType
  mv /tmp/installbuilder_installer.log $binDirectory/deadline-client.log
  [ $machineType == Scheduler ] && repositoryPath=$installRoot || repositoryPath="/mnt/deadline"
  echo "$binPathScheduler/deadlinecommand -StoreDatabaseCredentials $mongoDBUsername $mongoDBPassword" >> $aaaProfile
  echo "$binPathScheduler/deadlinecommand -ChangeRepository Direct $repositoryPath" >> $aaaProfile
  echo "Customize (End): Deadline Client"

  binPaths="$binPaths:$binPathScheduler"
fi

if [ $machineType == Workstation ]; then
  echo "Customize (Start): HP Anyware"
  versionInfo="23.12"
  [ "$gpuProvider" == "" ] && processType="pcoip-agent-standard" || processType="pcoip-agent-graphics"
  installFile="pcoip-agent-offline-rocky8.8_$versionInfo.2-1.el8.x86_64.tar.gz"
  downloadUrl="$binStorageHost/Teradici/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  mkdir -p $processType
  tar -xzf $installFile -C $processType
  cd $processType
  RunProcess "./install-pcoip-agent.sh $processType usb-vhci" $binDirectory/$processType
  cd $binDirectory
  echo "Customize (End): HP Anyware"
fi

echo "Customize (PATH): ${binPaths:1}"
echo 'PATH=$PATH'$binPaths >> $aaaProfile
