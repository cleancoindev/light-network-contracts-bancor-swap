module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*", // match any network
            gas: "99999999"
        },
        live: {
            host: '127.0.0.1',
            post: 8545,
            network_id: 1,
            gasPrice: 5000000000, //5gwei
            gas: 450000,
            from: '0xCaB2F51D80bfe9965cDFB2692B24C5c28c8415AF'
        }
    }
};
