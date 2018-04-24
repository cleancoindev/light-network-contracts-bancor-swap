module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*", // match any network
            gas: "99999999"
        },
        live: {
            host: "localhost",
            post: 8545,
            network_id: "1",
            from: "0xcab2f51d80bfe9965cdfb2692b24c5c28c8415af"
        }
    }
};
