const hosts = [
    // lab servers
    "australia",
    "belgium",
    "canada",
    "denmark",
    "egypt",
    "france",
    "greece",
    "hungary",
    "india",
    "japan",
    "korea",
    "laos",
    "malaysia",
    "nepal",
    "oman",
    "peru",
    "qatar",
    "russia",

    // NAS in the lab
    "192.168.100.20",
    "192.168.100.21",
    "192.168.100.22",

    // management servers
    "nis-server",
    "iyatomi-gw.k.hosei.ac.jp",

    // plant-ai servers
    "plant-ai00",
    "plant-ai01",
    "plant-ai02",
    "plant-ai03",
    "plant-ai04",
    "plant-ai05",
    "plant-ai06",
    "plant-ai07",

    // IPMI for the plant-ai servers
    "plant-ai00-ipmi",
    "plant-ai01-ipmi",
    "plant-ai02-ipmi",
    "plant-ai03-ipmi",
    "plant-ai04-ipmi",
    "plant-ai05-ipmi",
    "plant-ai06-ipmi",
    "plant-ai07-ipmi",

    // other university services
    "webprint.k.hosei.ac.jp",
    "opac.lib.hosei.ac.jp",

    // academic sites
    "www.sciencedirect.com",
    "ieeexplore.ieee.org",
    "dl.acm.org",
    "www.ncbi.nlm.nih.gov",
    "www.spiedigitallibrary.org",
    "analyticalsciencejournals.onlinelibrary.wiley.com"
]

function FindProxyForURL(url, host) {
    if (hosts.includes(host)) {
        return "SOCKS5 pi-proxy:10603";
    }
    return "DIRECT";
}
