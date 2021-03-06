#' Downsample analysis
#'
#'Downsample the CpG coverage matrix for saturation analysis
#'@param bs bsseq object
#'@param subSample number of CpGs to subsample
#'Default value is 1000000.
#'@param offset how many CpGs to offset when subsampling
#'Default value is set to be 50000, i.e. first 50000 CpGs will
#'be ignored in subsampling.
#'@param dsRates downsampling rate. i.e. the probabaility of sampling
#'a single CpG
#'default is list of probabilities ranging from 0.01 to 1
#'0.01 0.02 0.05 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90
#'For more continuous saturation curve dsRates can be changed to add more
#'sampling rates
#'@return Data frame with the CpG coverage for each sample at each
#'sampling rate
#'@examples
#'directory <- system.file("extdata/bismark_data", package='scmeth')
#'bs <- HDF5Array::loadHDF5SummarizedExperiment(directory)
#'scmeth::downsample(bs)
#'@importFrom stats dbinom
#'@importFrom bsseq getCoverage
#'
#'@export


downsample <- function(bs, dsRates = c(0.01, 0.02, 0.05, seq(0.1, 0.9, 0.1)), subSample=1e6, offset=50000){
    nCpGs <- nrow(bs)

    if (nCpGs<(subSample + offset)){
        bs <- bs
        subSample <- nCpGs
    }else{
        bs <- bs[offset:(subSample + offset)]
    }


    covMatrix <- bsseq::getCoverage(bs)
    nSamples <- dim(covMatrix)[2]
    downSampleMatrix <- matrix(nrow=length(dsRates) + 1, ncol=nSamples)
    maxCov <- 20
    nonZeroProbMatrix <- matrix(nrow=(length(dsRates) + 1), ncol=maxCov)

    for (i in seq_len(length(dsRates))){
        nonZeroProbMatrix[i,] <- 1 - dbinom(0, seq_len(maxCov), dsRates[i])
    }

    nonZeroProbMatrix[(length(dsRates) + 1),] <- 1

    countMatrix <- sapply(seq_len(ncol(covMatrix)), function(i) {
        cv = as.vector(covMatrix[,i])
        cv[cv>maxCov ] <- maxCov
        tab <- table(cv)
        tab <- tab[names(tab)!="0"]
        x <- rep(0, maxCov)
        x[as.numeric(names(tab))] <- tab
        x
    })

    downSampleMatrix <- round(nonZeroProbMatrix %*% countMatrix)
    downSampleMatrix <- downSampleMatrix*(nCpGs/subSample)

    rownames(downSampleMatrix) <- c(dsRates, 1)
    return(downSampleMatrix)
}
