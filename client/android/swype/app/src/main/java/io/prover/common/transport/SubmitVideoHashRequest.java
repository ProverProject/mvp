package io.prover.common.transport;

import org.ethereum.core.Transaction;
import org.json.JSONException;
import org.spongycastle.util.Arrays;
import org.spongycastle.util.BigIntegers;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;

import io.prover.common.transport.responce.SubmitVideoHashResponce;
import io.prover.common.transport.responce.SwypeCodeInfo;

/**
 * Created by babay on 15.11.2017.
 */

public class SubmitVideoHashRequest extends TransactionNetworkRequest<SubmitVideoHashResponce> {

    protected static final int GAS_LIMIT = 80_000;
    private static final int SUDMIT_VIDEO_FILE_DATA = 0xa0ee3ecf;
    private static final String METHOD = "submit-media-hash";
    private final SwypeCodeInfo swypeCodeInfo;
    private final File videoFile;

    private byte[] videoFileHash;

    public SubmitVideoHashRequest(NetworkSession session, SwypeCodeInfo swypeCodeInfo, File videoFile, NetworkRequestListener listener) {
        super(session, METHOD, listener);
        this.swypeCodeInfo = swypeCodeInfo;
        this.videoFile = videoFile;
    }

    @Override
    protected SubmitVideoHashResponce parse(String source) throws IOException, JSONException {
        return new SubmitVideoHashResponce(source);
    }

    @Override
    protected Transaction createTransaction() {
        if (videoFileHash == null) {
            try {
                videoFileHash = calculateFileHash();
            } catch (NoSuchProviderException | NoSuchAlgorithmException | IOException e) {
                throw new RuntimeException(e);
            }
        }

        byte[] gasLimit = BigIntegers.asUnsignedByteArray(BigInteger.valueOf(GAS_LIMIT));
        byte[] operation = BigIntegers.asUnsignedByteArray(BigInteger.valueOf(SUDMIT_VIDEO_FILE_DATA));
        byte[] data = Arrays.concatenate(operation, videoFileHash, swypeCodeInfo.hashBytes);
        byte[] nonce = BigIntegers.asUnsignedByteArray(session.getNonce());
        Transaction transaction = new Transaction(nonce, session.getGasPrice(), gasLimit, session.getContractAddress(), new byte[]{0}, data);
        transaction.sign(session.key);
        return transaction;
    }

    private byte[] calculateFileHash() throws NoSuchProviderException, NoSuchAlgorithmException, IOException {
        MessageDigest digest = MessageDigest.getInstance("sha256", "SC");
        byte[] buf = new byte[4096];
        FileInputStream stream = new FileInputStream(videoFile);
        while (stream.available() > 0) {
            int amount = stream.read(buf);
            digest.update(buf, 0, amount);
        }
        return digest.digest();
    }
}