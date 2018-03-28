// Blashyrkh.maniac.coding
// BTC:1Maniaccv5vSQVuwrmRtfazhf2WsUJ1KyD DOGE:DManiac9Gk31A4vLw9fLN9jVDFAQZc2zPj

#ifndef _PngAnalyzer_h
#define _PngAnalyzer_h

#include "Analyzer.h"


class PngAnalyzer : public Analyzer
{
public:
    PngAnalyzer(
        const std::string &filename,
        const Config      &config);

    virtual Result analyzeFile() override;

private:
    const std::string _filename;
    const Config      _config;
};

#endif
