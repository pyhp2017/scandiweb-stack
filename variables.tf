variable "aws_region" {
    default = "eu-central-1"
}

variable "servers_public_key" {
    # The scandiweb public key. This is the default key used for all servers.
    default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDXkrXvB6eYbWqwoAWM3YJa5vLhW+83A1c4vinSbVVdxUsLTFgceKY9Ur7q0EIkFYetFkoLz5hnUgaPFOSuYEnVuHL9L7hT7y5RHL+pJBwBLcmkymmGTCI1+2lbBGru09+IvyW7HSNOxkojVTmcsN9v294CSuwHKj7QJ2FRuCo9G6lwfHhCJHLPr2E7X9wJcHCKwlpUoLdIHO6+5OQbEiyPBp4A46NeLWq/1cMJiv9catMb4EBO8LcOhpqGzsqcthEKSZj/R28JrPWHfsBV3dQ2PUgHPts0OP+ilJZSwGWZV8GYl+25TfuveiVI7Zqhj00dUycvLeRGiiYssK4zuVhjv0DALMOjcybp326F8zIvruYU/DPernBWSi10nA+foUFMruAZ5TcCUt1dIVzywbqJKBgHaYOTg87FnCwsY9gLbZB0ZcQzPrsfhaviEfPKF01Gba69t2XD4J+FgmZu0JE1IfPktaCIZtfaU/IipUNvrmS0KpkW93mmQ/r6JCSNKcKEhwbkjJBOXURtfgoKV3PGHCp+B7RHSjysAAOP4vSnnuaGa/pHAeq/fBBzQeD62whgvVwDUGHL/rBXHeQeF49PryZ06nV/LDFFmudac5dzIDK19zZ+o4mwAF7E8wxilb2WenmRwKwD0DqkEEhp6j1+J7rfUsqzo2DS/j/GDDf6aQ=="
}

variable "servers_private_key_path" {
    type = string
}

variable "magento2_private_ip" {
    default = "10.0.1.60"
}

variable "varnish_private_ip" {
    default = "10.0.1.61"
}

variable "acme_registration_email" {
    type = string
}
