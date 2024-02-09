fileSystems = {
  linux = [
    { # File Storage
      enable   = false
      iaasOnly = false
      mount = {
        type    = "aznfs"
        path    = "/mnt/content"
        source  = "xstudio1.blob.core.windows.net:/xstudio1/content"
        options = "sec=sys,proto=tcp,vers=3,nolock"
      }
    },
    { # File Cache
      enable   = false
      iaasOnly = false
      mount = {
        type    = "nfs"
        path    = "/mnt/content"
        source  = "cache-west.artist.studio:/content"
        options = "hard,proto=tcp,mountproto=tcp,retry=30,nolock"
      }
    },
    { # Job Scheduler
      enable   = true
      iaasOnly = true
      mount = {
        type    = "nfs"
        path    = "/mnt/deadline"
        source  = "scheduler.artist.studio:/deadline"
        options = "defaults"
      }
    }
  ]
  windows = [
    { # File Storage
      enable   = false
      iaasOnly = true
      mount = {
        type    = ""
        path    = "X:"
        source  = "\\\\xstudio1.blob.core.windows.net\\xstudio1\\content"
        options = "-o anon nolock"
        userName = ""
        password = ""
      }
    },
    { # File Cache
      enable   = false
      iaasOnly = true
      mount = {
        type    = ""
        path    = "X:"
        source  = "\\\\cache-west.artist.studio\\content"
        options = "-o anon nolock"
        userName = ""
        password = ""
      }
    },
    { # Job Scheduler
      enable   = true
      iaasOnly = true
      mount = {
        type     = ""
        path     = "S:"
        source   = "\\\\scheduler.artist.studio\\deadline"
        options  = "-o anon"
        userName = ""
        password = ""
      }
    }
  ]
}