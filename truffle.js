module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*", // match any network
            gas: "99999999"
        },
        live: {
            host: "127.0.0.1",
            post: 8545,
            network_id: "1",
        }
    }
};
